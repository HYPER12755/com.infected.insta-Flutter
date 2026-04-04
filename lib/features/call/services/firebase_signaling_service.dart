import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:infected_insta/features/call/models/call_model.dart';

/// Service that handles WebRTC signaling via Firebase Realtime Database
class FirebaseSignalingService {
  static final FirebaseSignalingService _instance =
      FirebaseSignalingService._internal();
  factory FirebaseSignalingService() => _instance;
  FirebaseSignalingService._internal();

  // Firebase references
  late final DatabaseReference _callsRef;
  late final DatabaseReference _signalingRef;

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Video renderers
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  // Current user info
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  // Current call
  CallModel? _currentCall;

  // Stream subscriptions
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidatesSubscription;

  // Event callbacks
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallUpdated;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallDeclined;
  Function()? onCallEnded;

  // WebRTC configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
  };

  /// Initialize the service
  void initialize({
    required String userId,
    required String userName,
    String? userAvatar,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserAvatar = userAvatar;
    _callsRef = FirebaseDatabase.instance.ref().child('calls');
    _signalingRef = FirebaseDatabase.instance.ref().child('signaling');

    _listenForIncomingCalls();
    debugPrint('FirebaseSignalingService initialized for user: $userId');
  }

  /// Set video renderers
  void setRenderers({RTCVideoRenderer? local, RTCVideoRenderer? remote}) {
    _localRenderer = local;
    _remoteRenderer = remote;
  }

  /// Get local stream
  MediaStream? get localStream => _localStream;

  /// Get current call
  CallModel? get currentCall => _currentCall;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get audio enabled status
  bool get isAudioEnabled =>
      _localStream?.getAudioTracks().firstOrNull?.enabled ?? false;

  /// Get video enabled status
  bool get isVideoEnabled =>
      _localStream?.getVideoTracks().firstOrNull?.enabled ?? false;

  /// Listen for incoming calls
  void _listenForIncomingCalls() {
    _callsRef
        .orderByChild('calleeId')
        .equalTo(_currentUserId)
        .onChildAdded
        .listen((event) async {
          if (event.snapshot.value != null) {
            final callData = Map<String, dynamic>.from(
              event.snapshot.value as Map,
            );
            final call = CallModel.fromJson(callData);

            if (call.status == CallStatus.ringing) {
              debugPrint('Incoming call: ${call.callId}');
              onIncomingCall?.call(call);

              // Listen to this call's updates
              _listenToCallUpdates(call.callId);
            }
          }
        });
  }

  /// Listen to call updates
  void _listenToCallUpdates(String callId) {
    _callSubscription?.cancel();
    _callSubscription = _callsRef.child(callId).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final callData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final call = CallModel.fromJson(callData);

        onCallUpdated?.call(call);

        if (call.status == CallStatus.accepted) {
          onCallAccepted?.call(call);
        } else if (call.status == CallStatus.declined) {
          onCallDeclined?.call(call);
        } else if (call.status == CallStatus.ended ||
            call.status == CallStatus.cancelled) {
          onCallEnded?.call();
        }
      }
    });
  }

  /// Create a new outgoing call
  Future<CallModel?> createCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required CallType callType,
  }) async {
    try {
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

      // Create offer
      final offer = await _createOffer();

      // Create updated call with offer
      final callWithOffer = call.copyWith(offerSdp: offer.sdp);

      // Save to Firebase
      await _callsRef.child(callWithOffer.callId).set(callWithOffer.toJson());

      // Set current call
      _currentCall = callWithOffer;

      // Listen to call updates
      _listenToCallUpdates(callWithOffer.callId);

      // Listen for ICE candidates
      _listenToIceCandidates(callWithOffer.callId);

      return callWithOffer;
    } catch (e) {
      debugPrint('Error creating call: $e');
      return null;
    }
  }

  /// Accept an incoming call
  Future<bool> acceptCall(CallModel call) async {
    try {
      _currentCall = call;

      // Initialize media if needed
      if (_localStream == null) {
        final success = await initializeMedia(
          videoEnabled: call.callType == CallType.video,
        );
        if (!success) return false;
      }

      // Create peer connection
      await _createPeerConnection();

      // Set remote description (the offer from caller)
      if (call.offerSdp != null) {
        final offer = RTCSessionDescription(call.offerSdp!, 'offer');
        await _peerConnection!.setRemoteDescription(offer);
      }

      // Create and set answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Update call in Firebase with answer
      await _callsRef.child(call.callId).update({
        'status': CallStatus.accepted.name,
        'answerSdp': answer.sdp,
      });

      // Listen for ICE candidates
      _listenToIceCandidates(call.callId);

      return true;
    } catch (e) {
      debugPrint('Error accepting call: $e');
      return false;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    await _callsRef.child(call.callId).update({
      'status': CallStatus.declined.name,
    });
    _cleanup();
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentCall != null) {
      await _callsRef.child(_currentCall!.callId).update({
        'status': CallStatus.ended.name,
      });
    }
    _cleanup();
  }

  /// Initialize local media
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

      // Set to local renderer
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }

      debugPrint('Local media initialized');
      return true;
    } catch (e) {
      debugPrint('Error initializing media: $e');
      return false;
    }
  }

  /// Create peer connection
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_configuration);

    // Add local tracks
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) async {
      // candidate is non-nullable in newer flutter_webrtc versions
      if (_currentCall != null) {
        await _signalingRef
            .child(_currentCall!.callId)
            .child('candidates')
            .child(_currentUserId!)
            .push()
            .set(candidate.toMap());
      }
    };

    // Handle remote track
    _peerConnection!.onTrack = (event) {
      debugPrint('Remote track: ${event.track.kind}');
      if (_remoteRenderer != null && event.streams.isNotEmpty) {
        _remoteRenderer!.srcObject = event.streams[0];
      }
    };

    // Handle connection state
    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('ICE Connection State: $state');
    };
  }

  /// Create offer
  Future<RTCSessionDescription> _createOffer() async {
    await _createPeerConnection();

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    return offer;
  }

  /// Listen to ICE candidates from remote
  void _listenToIceCandidates(String callId) {
    _candidatesSubscription?.cancel();
    _candidatesSubscription = _signalingRef
        .child(callId)
        .child('candidates')
        .onChildAdded
        .listen((event) async {
          if (event.snapshot.value != null && _peerConnection != null) {
            final candidateData = Map<String, dynamic>.from(
              event.snapshot.value as Map,
            );
            final candidate = RTCIceCandidate(
              candidateData['candidate'] as String,
              candidateData['sdpMid'] as String?,
              candidateData['sdpMLineIndex'] as int?,
            );
            await _peerConnection!.addCandidate(candidate);
          }
        });
  }

  /// Toggle audio
  void toggleAudio(bool enabled) {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = enabled;
      }
    }
  }

  /// Toggle video
  void toggleVideo(bool enabled) {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = enabled;
      }
    }
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        // Using Helper class for camera switching
        try {
          // The Helper class should have a method to switch camera
          // For now, this is a placeholder
          debugPrint('Camera switch requested for track: ${videoTrack.label}');
        } catch (e) {
          debugPrint('Error switching camera: $e');
        }
      }
    }
  }

  /// Cleanup resources
  void _cleanup() {
    _callSubscription?.cancel();
    _candidatesSubscription?.cancel();

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    _localRenderer?.srcObject = null;
    _remoteRenderer?.srcObject = null;

    _currentCall = null;
  }

  /// Dispose
  void dispose() {
    _cleanup();
  }
}
