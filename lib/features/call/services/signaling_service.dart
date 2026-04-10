import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:infected_insta/features/call/models/call_model.dart';

/// Callback types for signaling events
typedef OnCallCreated = void Function(CallModel call);
typedef OnCallUpdated = void Function(CallModel call);
typedef OnCallEnded = void Function(String callId);

/// Service that handles WebRTC signaling (Supabase Realtime)
class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

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

  // Event listeners
  OnCallCreated? onCallCreated;
  OnCallUpdated? onCallUpdated;
  OnCallEnded? onCallEnded;

  // Event callbacks for incoming calls
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallDeclined;
  Function()? onCallEndedCallback;

  /// Initialize the signaling service with current user info
  void initialize({
    required String userId,
    required String userName,
    String? userAvatar,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserAvatar = userAvatar;
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get current user name
  String? get currentUserName => _currentUserName;

  /// Get current user avatar
  String? get currentUserAvatar => _currentUserAvatar;

  /// Get local stream
  MediaStream? get localStream => _localStream;

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
        // Use the helper to switch camera
        await Helper.switchCamera(videoTrack);
      }
    }
  }

  /// Cleanup all resources
  void dispose() {
    // Stop local stream tracks
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream = null;
  }

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

  /// Set incoming call callback
  void setOnIncomingCall(Function(CallModel)? callback) {
    onIncomingCall = callback;
  }

  /// Set call accepted callback
  void setOnCallAccepted(Function(CallModel)? callback) {
    onCallAccepted = callback;
  }

  /// Set call declined callback
  void setOnCallDeclined(Function(CallModel)? callback) {
    onCallDeclined = callback;
  }

  /// Set call ended callback
  void setOnCallEnded(Function()? callback) {
    onCallEndedCallback = callback;
  }

  /// Create a new outgoing call (stub - Supabase Realtime not implemented)
  Future<CallModel?> createCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required CallType callType,
  }) async {
    // Initialize local media first
    final success = await initializeMedia(
      videoEnabled: callType == CallType.video,
    );
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
    debugPrint('Created call (stub - Supabase Realtime not implemented)');
    return call;
  }

  /// Accept an incoming call (stub)
  Future<bool> acceptCall(CallModel call) async {
    _currentCall = call;

    // Initialize media if needed
    if (_localStream == null) {
      final success = await initializeMedia(
        videoEnabled: call.callType == CallType.video,
      );
      if (!success) return false;
    }

    return true;
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    _currentCall = null;
    dispose();
  }

  /// End the current call
  Future<void> endCall() async {
    _currentCall = null;
    _peerConnection?.close();
    _peerConnection = null;
    onCallEndedCallback?.call();
    dispose();
  }

  /// Listen for incoming calls using Supabase Realtime
  /// This listens to the 'calls' table for incoming call invitations
  void listenForIncomingCalls() {
    if (_currentUserId == null) {
      debugPrint('listenForIncomingCalls: No user ID set');
      return;
    }

    try {
      // Use Supabase Realtime to listen for new calls where receiver is current user
      // The channel listens for INSERT events on the 'calls' table
      // For full implementation, should use the Supabase Realtime streaming API
      // or use the SupabaseSignalingService for WebRTC signaling
      debugPrint('Listening for incoming calls for user: $_currentUserId');
      debugPrint(
        'Note: Full implementation should use supabase channel subscription',
      );
    } catch (e) {
      debugPrint('Error setting up incoming call listener: $e');
    }
  }
}
