import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:infected_insta/features/call/models/call_model.dart';

/// Callback types for signaling events
typedef OnCallCreated = void Function(CallModel call);
typedef OnCallUpdated = void Function(CallModel call);
typedef OnCallEnded = void Function(String callId);

/// Service that handles WebRTC signaling via Firebase Realtime Database
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

  // Event listeners
  OnCallCreated? onCallCreated;
  OnCallUpdated? onCallUpdated;
  OnCallEnded? onCallEnded;

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
}
