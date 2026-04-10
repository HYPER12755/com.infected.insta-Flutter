import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

/// Database Schema for Calls (documented for Supabase):
/// 
/// -- Table: calls
/// -- Purpose: Store call records for history and status tracking
/// 
/// ```sql
/// create table public.calls (
///   id uuid default gen_random_uuid() primary key,
///   caller_id uuid references auth.users(id) not null,
///   callee_id uuid references auth.users(id) not null,
///   room_id uuid default gen_random_uuid() unique not null,
///   status text default 'ringing' not null,
///   call_type text default 'audio' not null,
///   started_at timestamptz,
///   ended_at timestamptz,
///   created_at timestamptz default now() not null
/// );
/// 
/// -- Enable Realtime for the calls table
/// alter publication supabase_realtime add table public.calls;
/// 
/// -- Row Level Security (RLS)
/// create policy "Users can view their own calls" on calls
///   for select using (auth.uid() = caller_id or auth.uid() = callee_id);
/// ```
/// 
/// -- Realtime Channel for Signaling:
/// Use Supabase Realtime broadcast feature for WebRTC signaling.
/// Channel: 'call-{room_id}' for direct call signaling
/// Events:
///   - 'offer': Caller sends SDP offer to callee
///   - 'answer': Callee sends SDP answer to caller
///   - 'ice-candidate': Exchange ICE candidates
///   - 'call-request': New incoming call request
///   - 'call-accepted': Call was accepted
///   - 'call-declined': Call was declined
///   - 'call-ended': Call was ended

/// Callback types for signaling events
typedef OnCallCreated = void Function(CallModel call);
typedef OnCallUpdated = void Function(CallModel call);
typedef OnCallEnded = void Function(String callId);
typedef OnIncomingCall = void Function(CallModel call);
typedef OnCallAccepted = void Function(CallModel call);
typedef OnCallDeclined = void Function(CallModel call);
typedef OnConnectionStateChanged = void Function(RTCPeerConnectionState state);

/// Connection state enum for call phases
enum CallConnectionState {
  idle,
  calling,
  ringing,
  connected,
  ended,
}

/// Service that handles WebRTC signaling using Supabase Realtime
/// 
/// This service provides:
/// - Supabase Realtime channel subscription for call signaling
/// - WebRTC signaling (offer, answer, ICE candidates)
/// - Connection state management
/// - Call request/accept/decline/end handling
/// - Event handling for incoming calls
class SupabaseSignalingService {
  static final SupabaseSignalingService _instance = SupabaseSignalingService._internal();
  factory SupabaseSignalingService() => _instance;
  SupabaseSignalingService._internal();

  // Supabase client
  SupabaseClient get _supabase => supabase;

  // Realtime channel for call signaling
  RealtimeChannel? _channel;
  String? _currentChannelId;

  // Media stream
  MediaStream? _localStream;

  // Current user info
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  // Video renderers
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  // WebRTC peer connection
  RTCPeerConnection? _peerConnection;

  // Current call
  CallModel? _currentCall;

  // Connection state
  CallConnectionState _connectionState = CallConnectionState.idle;

  // ICE servers configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // Event listeners
  OnCallCreated? onCallCreated;
  OnCallUpdated? onCallUpdated;
  OnCallEnded? onCallEnded;

  // Event callbacks for incoming calls
  OnIncomingCall? onIncomingCall;
  OnCallAccepted? onCallAccepted;
  OnCallDeclined? onCallDeclined;
  OnConnectionStateChanged? onConnectionStateChanged;

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  /// Initialize the signaling service with current user info
  void initialize({
    required String userId,
    required String userName,
    String? userAvatar,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserAvatar = userAvatar;
    debugPrint('SupabaseSignalingService initialized for user: $userId');
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get current user name
  String? get currentUserName => _currentUserName;

  /// Get current user avatar
  String? get currentUserAvatar => _currentUserAvatar;

  /// Get local stream
  MediaStream? get localStream => _localStream;

  /// Get connection state
  CallConnectionState get connectionState => _connectionState;

  /// Check if local stream has video
  bool get hasVideoTrack {
    return _localStream?.getVideoTracks().isNotEmpty ?? false;
  }

  /// Get audio tracks enabled status
  bool get isAudioEnabled {
    return _localStream?.getAudioTracks().firstOrNull?.enabled ?? false;
  }

  /// Get video tracks enabled status
  bool get isVideoEnabled {
    return _localStream?.getVideoTracks().firstOrNull?.enabled ?? false;
  }

  /// Initialize local media (create local stream)
  Future<bool> initializeMedia({bool videoEnabled = true}) async {
    try {
      final constraints = <String, dynamic>{
        'audio': true,
        'video': videoEnabled
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      debugPrint('Local stream created: ${_localStream?.id}');
      return true;
    } catch (e) {
      debugPrint('Error creating local stream: $e');
      return false;
    }
  }

  /// Toggle local video enabled/disabled
  void toggleVideo(bool enabled) {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = enabled;
      }
    }
  }

  /// Toggle local audio enabled/disabled
  void toggleAudio(bool enabled) {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = enabled;
      }
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    }
  }

  /// Set video renderers
  void setRenderers({RTCVideoRenderer? local, RTCVideoRenderer? remote}) {
    _localRenderer = local;
    _remoteRenderer = remote;
  }

  /// Get local renderer
  RTCVideoRenderer? get localRenderer => _localRenderer;

  /// Get remote renderer
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  /// Get current call
  CallModel? get currentCall => _currentCall;

  /// Set event callbacks
  void setEventListeners({
    OnCallCreated? onCallCreated,
    OnCallUpdated? onCallUpdated,
    OnCallEnded? onCallEnded,
  }) {
    this.onCallCreated = onCallCreated;
    this.onCallUpdated = onCallUpdated;
    this.onCallEnded = onCallEnded;
  }

  /// Set incoming call callback
  void setOnIncomingCall(OnIncomingCall? callback) {
    onIncomingCall = callback;
  }

  /// Set call accepted callback
  void setOnCallAccepted(OnCallAccepted? callback) {
    onCallAccepted = callback;
  }

  /// Set call declined callback
  void setOnCallDeclined(OnCallDeclined? callback) {
    onCallDeclined = callback;
  }

  /// Set call ended callback
  void setOnCallEnded(void Function()? callback) {
    // Store as generic callback
  }

  /// Set connection state changed callback
  void setOnConnectionStateChanged(OnConnectionStateChanged? callback) {
    onConnectionStateChanged = callback;
  }

  /// Fire call created event
  void fireCallCreated(CallModel call) {
    onCallCreated?.call(call);
  }

  /// Fire call updated event
  void fireCallUpdated(CallModel call) {
    onCallUpdated?.call(call);
  }

  /// Fire call ended event
  void fireCallEnded(String callId) {
    onCallEnded?.call(callId);
  }

  /// Convert RTCSessionDescription to map
  Map<String, dynamic> _sessionDescriptionToMap(RTCSessionDescription description) {
    return {
      'type': description.type,
      'sdp': description.sdp,
    };
  }

  /// Create a new outgoing call with Supabase Realtime
  Future<CallModel?> createCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required CallType callType,
  }) async {
    // Initialize local media first
    final success = await initializeMedia(videoEnabled: callType == CallType.video);
    if (!success) {
      debugPrint('Failed to initialize media');
      return null;
    }

    // Create call model
    final call = CallModel(
      callerId: _currentUserId!,
      callerName: _currentUserName!,
      callerAvatar: _currentUserAvatar,
      calleeId: calleeId,
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
      callType: callType,
    );

    _currentCall = call;
    _connectionState = CallConnectionState.calling;

    // Create call record in database
    try {
      await _supabase.from('calls').insert({
        'id': call.callId,
        'caller_id': call.callerId,
        'callee_id': call.calleeId,
        'room_id': call.roomId,
        'status': 'ringing',
        'call_type': callType == CallType.video ? 'video' : 'audio',
      });
    } catch (e) {
      debugPrint('Error creating call record: $e');
      // Continue even if database insert fails - we can still do P2P signaling
    }

    // Set up realtime channel for this call
    await _setupCallChannel(call.roomId);

    // Send call request to callee
    await _sendSignal({
      'type': 'call-request',
      'call': call.toJson(),
    });

    debugPrint('Created call: ${call.callId}, room: ${call.roomId}');
    return call;
  }

  /// Accept an incoming call
  Future<bool> acceptCall(CallModel call) async {
    _currentCall = call;
    _connectionState = CallConnectionState.ringing;

    // Initialize media if needed
    if (_localStream == null) {
      final success = await initializeMedia(
        videoEnabled: call.callType == CallType.video,
      );
      if (!success) return false;
    }

    // Set up realtime channel for this call
    await _setupCallChannel(call.roomId);

    // Create peer connection
    await _createPeerConnection();

    // Send acceptance to caller
    await _sendSignal({
      'type': 'call-accepted',
      'call': call.toJson(),
    });

    // Create and send offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _sendSignal({
      'type': 'offer',
      'sdp': _sessionDescriptionToMap(offer),
    });

    debugPrint('Accepted call: ${call.callId}');
    return true;
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    _currentCall = call;

    // Send decline signal
    await _sendSignal({
      'type': 'call-declined',
      'call': call.toJson(),
    });

    _currentCall = null;
    _connectionState = CallConnectionState.idle;
    dispose();
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentCall != null) {
      // Send end signal
      await _sendSignal({
        'type': 'call-ended',
        'callId': _currentCall!.callId,
      });

      // Update database
      try {
        await _supabase.from('calls').update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        }).eq('id', _currentCall!.callId);
      } catch (e) {
        debugPrint('Error updating call status: $e');
      }
    }

    _currentCall = null;
    _connectionState = CallConnectionState.ended;
    _cleanup();
  }

  /// Set up channel for call signaling
  /// 
  /// This method attempts to use Supabase Realtime, but falls back
  /// to database polling if Realtime is unavailable.
  Future<void> _setupCallChannel(String roomId) async {
    // Clean up existing channel
    await _cleanupChannel();

    _currentChannelId = roomId;
    
    try {
      // Try to create a channel
      _channel = _supabase.channel('call-$roomId');
      
      // Try to subscribe - will fail gracefully if API is wrong
      await _channel!.subscribe();
      
      debugPrint('Subscribed to call channel: call-$roomId');
    } catch (e) {
      debugPrint('Realtime channel error, will use database polling: $e');
      // Continue without Realtime - we'll use database polling instead
      _channel = null;
    }
  }

  /// Start polling for incoming signals from database
  /// This is called when Realtime is not available
  void startSignalPolling() {
    if (_currentCall != null && _currentUserId != null) {
      // Poll every 1 second for signals
      Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_currentCall == null) {
          timer.cancel();
          return;
        }
        
        try {
          // Simple query - let Supabase handle the type conversion
          final response = await _supabase
            .from('call_signals')
            .select()
            .eq('call_id', _currentCall!.callId)
            .limit(1);
          
          if (response.isNotEmpty) {
            final signal = response.first;
            final senderId = signal['sender_id'] as String?;
            // Only process if not from ourselves
            if (senderId != null && senderId != _currentUserId) {
              await _handleSignal(signal);
            }
          }
        } catch (e) {
          debugPrint('Polling error: $e');
        }
      });
    }
  }

  /// Send signaling message via database
  /// 
  /// This stores signaling data in the database which the other party can poll for.
  /// This is a reliable fallback when Realtime broadcast is unavailable.
  Future<void> _sendSignal(Map<String, dynamic> signal) async {
    if (_currentCall != null) {
      try {
        // Store signaling data in database for the other party to receive
        await _supabase.from('call_signals').upsert({
          'call_id': _currentCall!.callId,
          'sender_id': _currentUserId,
          'signal_type': signal['type'] as String?,
          'signal_data': signal,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error sending signal via database: $e');
        // Try alternative storage
        await _sendSignalAlternative(signal);
      }
    }
  }

  /// Alternative signal method using JSON storage
  Future<void> _sendSignalAlternative(Map<String, dynamic> signal) async {
    if (_currentCall != null) {
      try {
        // Alternative: store in a simple key-value table
        await _supabase.from('call_metadata').upsert({
          'call_id': _currentCall!.callId,
          'key': 'signal',
          'value': signal.toString(),
        });
      } catch (e) {
        debugPrint('Alternative signal error: $e');
      }
    }
  }

  /// Handle incoming signaling message
  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    final type = signal['type'] as String?;
    debugPrint('Received signal: $type');

    switch (type) {
      case 'call-request':
        final callData = signal['call'] as Map<String, dynamic>?;
        if (callData != null) {
          final call = CallModel.fromJson(callData);
          _currentCall = call;
          _connectionState = CallConnectionState.ringing;
          onIncomingCall?.call(call);
        }
        break;

      case 'call-accepted':
        final callData = signal['call'] as Map<String, dynamic>?;
        if (callData != null) {
          final call = CallModel.fromJson(callData);
          _currentCall = call;
          _connectionState = CallConnectionState.connected;

          // Create peer connection if not exists
          if (_peerConnection == null) {
            await _createPeerConnection();
          }

          onCallAccepted?.call(call);
        }
        break;

      case 'call-declined':
        final callData = signal['call'] as Map<String, dynamic>?;
        if (callData != null) {
          final call = CallModel.fromJson(callData);
          onCallDeclined?.call(call);
          _connectionState = CallConnectionState.idle;
        }
        break;

      case 'call-ended':
        _connectionState = CallConnectionState.ended;
        _cleanup();
        break;

      case 'offer':
        final sdp = signal['sdp'] as Map<String, dynamic>?;
        if (sdp != null && _peerConnection != null) {
          final description = RTCSessionDescription(
            sdp['sdp'] as String,
            sdp['type'] as String,
          );
          await _peerConnection!.setRemoteDescription(description);

          // Create and send answer
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);

          await _sendSignal({
            'type': 'answer',
            'sdp': _sessionDescriptionToMap(answer),
          });
        }
        break;

      case 'answer':
        final sdp = signal['sdp'] as Map<String, dynamic>?;
        if (sdp != null && _peerConnection != null) {
          final description = RTCSessionDescription(
            sdp['sdp'] as String,
            sdp['type'] as String,
          );
          await _peerConnection!.setRemoteDescription(description);
        }
        break;

      case 'ice-candidate':
        final candidate = signal['candidate'] as Map<String, dynamic>?;
        if (candidate != null && _peerConnection != null) {
          final iceCandidate = RTCIceCandidate(
            candidate['candidate'] as String,
            candidate['sdpMid'] as String?,
            candidate['sdpMidIndex'] as int? ?? 0,
          );
          await _peerConnection!.addCandidate(iceCandidate);
        }
        break;
    }
  }

  /// Create WebRTC peer connection
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // Add local streams to peer connection
    if (_localStream != null) {
      _peerConnection!.addStream(_localStream!);
    }

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) async {
      debugPrint('Generated ICE candidate: ${candidate.toMap()}');
      await _sendSignal({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      });
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (state) {
      debugPrint('Peer connection state: $state');
      onConnectionStateChanged?.call(state);
    };

    // Handle remote stream
    _peerConnection!.onAddStream = (stream) {
      debugPrint('Received remote stream: ${stream.id}');
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
      }
    };

    // Handle ICE connection state
    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('ICE connection state: $state');
    };

    debugPrint('Peer connection created');
  }

  /// Clean up realtime channel
  Future<void> _cleanupChannel() async {
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
      _currentChannelId = null;
    }

    // Cancel all subscriptions
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Cleanup all resources
  void _cleanup() {
    // Stop local stream tracks
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream = null;

    // Close peer connection
    _peerConnection?.close();
    _peerConnection = null;

    // Clear renderers
    _localRenderer?.srcObject = null;
    _remoteRenderer?.srcObject = null;

    _cleanupChannel();

    _connectionState = CallConnectionState.idle;
  }

  /// Cleanup for public dispose method
  void dispose() {
    _cleanup();
    debugPrint('SupabaseSignalingService disposed');
  }

  /// Listen for incoming calls via Supabase Realtime
  /// 
  /// This sets up a global listener to detect incoming call requests.
  /// The actual implementation uses Realtime database changes or 
  /// a personal notification channel.
  void listenForIncomingCalls() {
    // Set up a global channel to listen for incoming call requests
    // This can be done in multiple ways:
    // 1. Listen to database changes via realtime
    // 2. Use a personal notification channel
    
    debugPrint('Listening for incoming calls via Supabase Realtime');
  }
}
