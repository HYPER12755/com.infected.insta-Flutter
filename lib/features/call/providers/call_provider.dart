import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/call/services/supabase_signaling_service.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

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

/// Call provider — manages WebRTC call lifecycle via SupabaseSignalingService
class CallProvider extends StateNotifier<CallState> {
  final SupabaseSignalingService _signalingService;
  RTCVideoRenderer? _externalLocalRenderer;
  RTCVideoRenderer? _externalRemoteRenderer;

  CallProvider(this._signalingService) : super(const CallState()) {
    _initUser();
  }

  void _initUser() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _signalingService.initialize(
        userId: user.id,
        userName: user.userMetadata?['username'] as String? ??
            user.email?.split('@')[0] ?? 'User',
        userAvatar: user.userMetadata?['avatar_url'] as String?,
      );
      // Wire incoming call handler before starting to listen
      _signalingService.onIncomingCall = (call) {
        state = state.copyWith(hasIncomingCall: true, incomingCall: call);
      };
      _signalingService.listenForIncomingCalls();
    }
  }

  /// Allow the VideoCallScreen to inject its own renderers
  void setRenderers({
    required RTCVideoRenderer local,
    required RTCVideoRenderer remote,
  }) {
    _externalLocalRenderer = local;
    _externalRemoteRenderer = remote;
    _signalingService.setRenderers(local: local, remote: remote);
  }

  Future<bool> makeCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required CallType callType,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated');
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
          currentCall: call, isInCall: true, isConnecting: false,
          isVideoEnabled: callType == CallType.video);
        return true;
      }
      state = state.copyWith(isConnecting: false, error: 'Failed to create call');
      return false;
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> acceptCall() async {
    if (state.incomingCall == null) return false;
    state = state.copyWith(isConnecting: true, error: null);
    try {
      final ok = await _signalingService.acceptCall(state.incomingCall!);
      if (ok) {
        state = state.copyWith(
          currentCall: state.incomingCall, isInCall: true,
          isConnecting: false, hasIncomingCall: false, incomingCall: null,
          isVideoEnabled: state.incomingCall!.callType == CallType.video);
        return true;
      }
      state = state.copyWith(isConnecting: false, error: 'Failed to accept',
          hasIncomingCall: false, incomingCall: null);
      return false;
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: e.toString(),
          hasIncomingCall: false, incomingCall: null);
      return false;
    }
  }

  Future<void> declineCall() async {
    if (state.incomingCall != null) {
      await _signalingService.declineCall(state.incomingCall!);
      state = state.copyWith(hasIncomingCall: false, incomingCall: null);
    }
  }

  Future<void> endCall() async {
    await _signalingService.endCall();
    _cleanup();
  }

  /// toggleAudio(enabled) — passing explicit value so VideoCallScreen controls state
  void toggleAudio(bool enabled) {
    _signalingService.toggleAudio(enabled);
    state = state.copyWith(isAudioEnabled: enabled);
  }

  /// toggleVideo(enabled)
  void toggleVideo(bool enabled) {
    _signalingService.toggleVideo(enabled);
    state = state.copyWith(isVideoEnabled: enabled);
  }

  Future<void> switchCamera() async {
    await _signalingService.switchCamera();
  }

  void _cleanup() {
    state = const CallState();
    _externalLocalRenderer?.srcObject = null;
    _externalRemoteRenderer?.srcObject = null;
  }

  RTCVideoRenderer? get localRenderer => _externalLocalRenderer;
  RTCVideoRenderer? get remoteRenderer => _externalRemoteRenderer;

  @override
  void dispose() {
    _signalingService.dispose();
    super.dispose();
  }
}

final signalingServiceProvider = Provider<SupabaseSignalingService>((ref) {
  return SupabaseSignalingService();
});

final callProvider = StateNotifierProvider<CallProvider, CallState>((ref) {
  return CallProvider(ref.watch(signalingServiceProvider));
});

