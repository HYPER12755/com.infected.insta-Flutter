import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/call/services/firebase_signaling_service.dart';

/// State class for the call feature
class CallState {
  final CallModel? currentCall;
  final bool isInCall;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isConnecting;
  final String? error;
  final bool hasIncomingCall;
  final CallModel? incomingCall;

  const CallState({
    this.currentCall,
    this.isInCall = false,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isConnecting = false,
    this.error,
    this.hasIncomingCall = false,
    this.incomingCall,
  });

  CallState copyWith({
    CallModel? currentCall,
    bool? isInCall,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isConnecting,
    String? error,
    bool? hasIncomingCall,
    CallModel? incomingCall,
  }) {
    return CallState(
      currentCall: currentCall ?? this.currentCall,
      isInCall: isInCall ?? this.isInCall,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
      hasIncomingCall: hasIncomingCall ?? this.hasIncomingCall,
      incomingCall: incomingCall ?? this.incomingCall,
    );
  }
}

/// Call provider for state management using Riverpod
class CallProvider extends StateNotifier<CallState> {
  final FirebaseSignalingService _signalingService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  CallProvider(this._signalingService) : super(const CallState()) {
    _initializeRenderers();
    _initializeUser();
  }

  /// Initialize video renderers
  Future<void> _initializeRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _signalingService.setRenderers(
        local: _localRenderer,
        remote: _remoteRenderer,
      );
    } catch (e) {
      debugPrint('Error initializing renderers: $e');
    }
  }

  /// Initialize current user from Firebase Auth
  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName =
          user.displayName ?? user.email?.split('@').first ?? 'User';
      _currentUserAvatar = user.photoURL;

      _signalingService.initialize(
        userId: _currentUserId!,
        userName: _currentUserName!,
        userAvatar: _currentUserAvatar,
      );

      // Set up event listeners
      _signalingService.onIncomingCall = _handleIncomingCall;
      _signalingService.onCallAccepted = _handleCallAccepted;
      _signalingService.onCallDeclined = _handleCallDeclined;
      _signalingService.onCallEnded = _handleCallEnded;
    }
  }

  /// Handle incoming call
  void _handleIncomingCall(CallModel call) {
    state = state.copyWith(hasIncomingCall: true, incomingCall: call);
  }

  /// Handle call accepted
  void _handleCallAccepted(CallModel call) {
    state = state.copyWith(
      currentCall: call,
      isInCall: true,
      isConnecting: false,
    );
  }

  /// Handle call declined
  void _handleCallDeclined(CallModel call) {
    state = state.copyWith(
      currentCall: call,
      isConnecting: false,
      error: 'Call declined',
    );
    _cleanup();
  }

  /// Handle call ended
  void _handleCallEnded() {
    _cleanup();
  }

  /// Cleanup after call ends
  void _cleanup() {
    state = const CallState();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
  }

  /// Make an outgoing call
  Future<bool> makeCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required CallType callType,
  }) async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isConnecting: true, error: null);

    try {
      final call = await _signalingService.createCall(
        calleeId: calleeId,
        calleeName: calleeName,
        calleeAvatar: calleeAvatar,
        callType: callType,
      );

      if (call != null) {
        state = state.copyWith(
          currentCall: call,
          isInCall: true,
          isConnecting: false,
          isVideoEnabled: callType == CallType.video,
        );
        return true;
      } else {
        state = state.copyWith(
          isConnecting: false,
          error: 'Failed to create call',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Error making call: $e',
      );
      return false;
    }
  }

  /// Accept incoming call
  Future<bool> acceptCall() async {
    if (state.incomingCall == null) return false;

    state = state.copyWith(isConnecting: true, error: null);

    try {
      final success = await _signalingService.acceptCall(state.incomingCall!);

      if (success) {
        state = state.copyWith(
          currentCall: state.incomingCall,
          isInCall: true,
          isConnecting: false,
          hasIncomingCall: false,
          incomingCall: null,
          isVideoEnabled: state.incomingCall!.callType == CallType.video,
        );
        return true;
      } else {
        state = state.copyWith(
          isConnecting: false,
          error: 'Failed to accept call',
          hasIncomingCall: false,
          incomingCall: null,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Error accepting call: $e',
        hasIncomingCall: false,
        incomingCall: null,
      );
      return false;
    }
  }

  /// Decline incoming call
  Future<void> declineCall() async {
    if (state.incomingCall != null) {
      await _signalingService.declineCall(state.incomingCall!);
      state = state.copyWith(hasIncomingCall: false, incomingCall: null);
    }
  }

  /// End current call
  Future<void> endCall() async {
    await _signalingService.endCall();
    _cleanup();
  }

  /// Toggle audio
  void toggleAudio() {
    final newState = !state.isAudioEnabled;
    _signalingService.toggleAudio(newState);
    state = state.copyWith(isAudioEnabled: newState);
  }

  /// Toggle video
  void toggleVideo() {
    final newState = !state.isVideoEnabled;
    _signalingService.toggleVideo(newState);
    state = state.copyWith(isVideoEnabled: newState);
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _signalingService.switchCamera();
  }

  /// Get local renderer
  RTCVideoRenderer get localRenderer => _localRenderer;

  /// Get remote renderer
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get current user name
  String? get currentUserName => _currentUserName;

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signalingService.dispose();
    super.dispose();
  }
}

/// Provider for FirebaseSignalingService
final signalingServiceProvider = Provider<FirebaseSignalingService>((ref) {
  return FirebaseSignalingService();
});

/// Provider for CallProvider
final callProvider = StateNotifierProvider<CallProvider, CallState>((ref) {
  final signalingService = ref.watch(signalingServiceProvider);
  return CallProvider(signalingService);
});
