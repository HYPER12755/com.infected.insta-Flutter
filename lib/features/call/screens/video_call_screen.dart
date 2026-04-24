import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/call/providers/call_provider.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  // Renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Call state
  bool _muted = false;
  bool _videoOff = false;
  bool _speakerOn = true;
  bool _frontCamera = true;
  bool _showControls = true;
  final bool _pipMode = false; // local video draggable PiP

  Timer? _durationTimer;
  Timer? _controlsTimer;
  int _durationSeconds = 0;

  // Local PiP position
  Offset _pipOffset = const Offset(16, 100);

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startTimer();
    _autoHideControls();
    // Force landscape not needed — keep portrait
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _durationTimer?.cancel();
    _controlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final provider = ref.read(callProvider.notifier);
    provider.setRenderers(
      local: _localRenderer,
      remote: _remoteRenderer,
    );
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
  }

  void _autoHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _autoHideControls();
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    ref.read(callProvider.notifier).toggleAudio(!_muted);
    HapticFeedback.selectionClick();
  }

  void _toggleVideo() {
    setState(() => _videoOff = !_videoOff);
    ref.read(callProvider.notifier).toggleVideo(!_videoOff);
    HapticFeedback.selectionClick();
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    // flutter_webrtc handles speaker routing via MediaStream constraints
    HapticFeedback.selectionClick();
  }

  Future<void> _flipCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    ref.read(callProvider.notifier).switchCamera();
    HapticFeedback.lightImpact();
  }

  void _endCall() {
    HapticFeedback.mediumImpact();
    ref.read(callProvider.notifier).endCall();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final call = callState.currentCall;
    final isVideoCall = call?.callType == CallType.video;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(children: [
          // ── Remote video (full screen) ───────────────────────────────────
          if (isVideoCall && !_videoOff)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: false,
              ),
            )
          else
            _buildAudioBackground(call),

          // ── Local PiP video (draggable) ─────────────────────────────────
          if (isVideoCall)
            Positioned(
              left: _pipOffset.dx,
              top: _pipOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _pipOffset = Offset(
                      (_pipOffset.dx + d.delta.dx)
                          .clamp(0, size.width - 120),
                      (_pipOffset.dy + d.delta.dy)
                          .clamp(0, size.height - 180),
                    );
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110, height: 160,
                    child: _videoOff
                        ? Container(color: const Color(0xFF2A2A3E),
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.videoSlash,
                                  color: Colors.white54, size: 24)))
                        : RTCVideoView(
                            _localRenderer,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            mirror: _frontCamera,
                          ),
                  ),
                ),
              ),
            ),

          // ── Top bar (animated show/hide) ─────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -120,
            left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent]),
              ),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const FaIcon(FontAwesomeIcons.chevronDown,
                      color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(call?.calleeName ?? call?.callerName ?? 'Call',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_formatDuration(_durationSeconds),
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ])),
                // Connection quality
                _connectionQualityIcon(callState),
              ]),
            ),
          ),

          // ── Bottom controls (animated show/hide) ─────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -160,
            left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent]),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(children: [
                // Top row: mute, video, speaker, flip
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  _ControlBtn(
                    icon: _muted
                        ? FontAwesomeIcons.microphoneSlash
                        : FontAwesomeIcons.microphone,
                    label: _muted ? 'Unmute' : 'Mute',
                    active: _muted,
                    onTap: _toggleMute,
                  ),
                  if (isVideoCall)
                    _ControlBtn(
                      icon: _videoOff
                          ? FontAwesomeIcons.videoSlash
                          : FontAwesomeIcons.video,
                      label: _videoOff ? 'Start Video' : 'Stop Video',
                      active: _videoOff,
                      onTap: _toggleVideo,
                    ),
                  _ControlBtn(
                    icon: _speakerOn
                        ? FontAwesomeIcons.volumeHigh
                        : FontAwesomeIcons.volumeXmark,
                    label: _speakerOn ? 'Speaker' : 'Earpiece',
                    active: false,
                    onTap: _toggleSpeaker,
                  ),
                  if (isVideoCall)
                    _ControlBtn(
                      icon: FontAwesomeIcons.rotateRight,
                      label: 'Flip',
                      active: false,
                      onTap: _flipCamera,
                    ),
                ]),
                const SizedBox(height: 24),
                // End call button
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.phoneSlash,
                          size: 28, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAudioBackground(CallModel? call) {
    final name = call?.calleeName ?? call?.callerName ?? '';
    final avatar = call?.calleeAvatar ?? call?.callerAvatar ?? '';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)])),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        CircleAvatar(
          radius: 72,
          backgroundColor: const Color(0xFF2A2A3E),
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
          child: avatar.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 52, color: Colors.white,
                      fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(height: 20),
        Text(name, style: const TextStyle(color: Colors.white,
            fontSize: 24, fontWeight: FontWeight.bold)),
      ])),
    );
  }

  Widget _connectionQualityIcon(CallState state) {
    return const FaIcon(FontAwesomeIcons.signal, color: Colors.green, size: 16);
  }
}

// ─── Control button ───────────────────────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(icon, size: 22,
                color: active ? Colors.black : Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
