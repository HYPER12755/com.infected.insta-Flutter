import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/call/providers/call_provider.dart';
import 'package:infected_insta/features/call/screens/video_call_screen.dart';

// ─── Entry-point call screen ──────────────────────────────────────────────────
class CallScreen extends ConsumerWidget {
  final String? calleeId;
  final String? calleeName;
  final String? calleeAvatar;
  final CallType? callType;

  const CallScreen({
    super.key,
    this.calleeId,
    this.calleeName,
    this.calleeAvatar,
    this.callType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    if (callState.hasIncomingCall && callState.incomingCall != null) {
      return _IncomingCallScreen(call: callState.incomingCall!);
    }

    if (calleeId != null && calleeName != null) {
      return _OutgoingCallScreen(
        calleeId: calleeId!,
        calleeName: calleeName!,
        calleeAvatar: calleeAvatar,
        callType: callType ?? CallType.audio,
      );
    }

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text('No call in progress',
          style: TextStyle(color: Colors.white54))),
    );
  }
}

// ─── Outgoing call (dialing) ──────────────────────────────────────────────────
class _OutgoingCallScreen extends ConsumerStatefulWidget {
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final CallType callType;

  const _OutgoingCallScreen({
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    required this.callType,
  });

  @override
  ConsumerState<_OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<_OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _callTimeout;
  bool _calling = false;
  bool _muted = false;
  bool _speakerOn = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _callTimeout?.cancel();
    super.dispose();
  }

  Future<void> _startCall() async {
    if (_calling) return;
    _calling = true;
    HapticFeedback.mediumImpact();

    final success = await ref.read(callProvider.notifier).makeCall(
      calleeId: widget.calleeId,
      calleeName: widget.calleeName,
      calleeAvatar: widget.calleeAvatar,
      callType: widget.callType,
    );

    // Auto-timeout after 45s if no answer
    _callTimeout = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        ref.read(callProvider.notifier).endCall();
        Navigator.pop(context);
      }
    });

    if (success && mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const VideoCallScreen()));
    }
  }

  void _cancel() {
    _callTimeout?.cancel();
    ref.read(callProvider.notifier).endCall();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.calleeAvatar ?? '';
    final isVideo = widget.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Blurred background ──
        if (avatar.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover,
                  color: Colors.black54, colorBlendMode: BlendMode.darken),
            ),
          )
        else
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)]),
          )),

        SafeArea(child: Column(children: [
          const SizedBox(height: 60),

          // Call type label
          Text(isVideo ? 'Video Call' : 'Audio Call',
              style: const TextStyle(color: Colors.white54, fontSize: 15,
                  letterSpacing: 0.5)),
          const SizedBox(height: 40),

          // ── Pulsing avatar ──
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(0xFFC039FF).withValues(alpha: 0.5),
                  blurRadius: 40, spreadRadius: 10)],
              ),
              child: CircleAvatar(
                radius: 72,
                backgroundColor: const Color(0xFF2A2A3E),
                backgroundImage: avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
                child: avatar.isEmpty
                    ? Text(widget.calleeName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 52, color: Colors.white,
                            fontWeight: FontWeight.bold)) : null,
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(widget.calleeName,
              style: const TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Animated "Calling..." dots
          _CallingIndicator(),

          const Spacer(),

          // ── Controls ──
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CallBtn(
              icon: _muted ? FontAwesomeIcons.microphoneSlash : FontAwesomeIcons.microphone,
              label: _muted ? 'Unmute' : 'Mute',
              bg: _muted ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.15),
              iconColor: _muted ? Colors.black : Colors.white,
              onTap: () => setState(() => _muted = !_muted),
            ),
            const SizedBox(width: 40),
            _CallBtn(
              icon: FontAwesomeIcons.phoneSlash,
              label: 'End',
              bg: Colors.red,
              iconColor: Colors.white,
              size: 72,
              onTap: _cancel,
            ),
            const SizedBox(width: 40),
            _CallBtn(
              icon: _speakerOn ? FontAwesomeIcons.volumeHigh : FontAwesomeIcons.volumeXmark,
              label: _speakerOn ? 'Speaker' : 'Earpiece',
              bg: Colors.white.withValues(alpha: 0.15),
              onTap: () => setState(() => _speakerOn = !_speakerOn),
            ),
          ]),
          const SizedBox(height: 60),
        ])),
      ]),
    );
  }
}

// ─── Incoming call screen ─────────────────────────────────────────────────────
class _IncomingCallScreen extends ConsumerStatefulWidget {
  final CallModel call;
  const _IncomingCallScreen({required this.call});

  @override
  ConsumerState<_IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<_IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _ringAnim = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    // Haptic pulse for incoming call
    _pulseHaptic();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  void _pulseHaptic() async {
    for (int i = 0; i < 20; i++) {
      if (!mounted) break;
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final avatar = call.callerAvatar ?? '';
    final isVideo = call.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Blurred bg
        if (avatar.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover,
                  color: Colors.black54, colorBlendMode: BlendMode.darken),
            ),
          )
        else
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0F3460), Color(0xFF0D0D1A)]))),

        SafeArea(child: Column(children: [
          const SizedBox(height: 40),
          Text(isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
              style: const TextStyle(color: Colors.white54, fontSize: 15,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('from', style: TextStyle(color: Colors.white.withValues(alpha: 0.35))),
          const SizedBox(height: 40),

          // ── Ringing avatar ──
          ScaleTransition(
            scale: _ringAnim,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 40, spreadRadius: 12),
                ],
              ),
              child: CircleAvatar(
                radius: 72,
                backgroundColor: const Color(0xFF2A2A3E),
                backgroundImage: avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
                child: avatar.isEmpty
                    ? Text(call.callerName.isNotEmpty
                          ? call.callerName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 52, color: Colors.white,
                            fontWeight: FontWeight.bold)) : null,
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(call.callerName,
              style: const TextStyle(color: Colors.white, fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              FaIcon(isVideo ? FontAwesomeIcons.video : FontAwesomeIcons.phone,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(isVideo ? 'Video Call' : 'Audio Call',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),

          const Spacer(),

          // ── Swipe to answer hint ──
          Text('Swipe to answer',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          const SizedBox(height: 24),

          // ── Accept / Decline ──
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            // Decline
            Column(children: [
              GestureDetector(
                onTap: () {
                  ref.read(callProvider.notifier).declineCall();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.phoneSlash,
                        size: 28, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),

            // Accept
            Column(children: [
              GestureDetector(
                onTap: () async {
                  final ok = await ref.read(callProvider.notifier).acceptCall();
                  if (ok && context.mounted) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const VideoCallScreen()));
                  }
                },
                child: Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                  child: Center(
                    child: FaIcon(
                      isVideo ? FontAwesomeIcons.video : FontAwesomeIcons.phone,
                      size: 28, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(isVideo ? 'Accept Video' : 'Accept',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 60),
        ])),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _CallBtn extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color bg;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CallBtn({
    required this.icon,
    required this.label,
    required this.bg,
    required this.onTap,
    this.iconColor = Colors.white,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: FaIcon(icon, size: size * 0.38, color: iconColor)),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]);
  }
}

class _CallingIndicator extends StatefulWidget {
  @override
  State<_CallingIndicator> createState() => _CallingIndicatorState();
}

class _CallingIndicatorState extends State<_CallingIndicator> {
  int _dots = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dots = (_dots % 3) + 1);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Text('Calling${'.' * _dots}',
        style: const TextStyle(color: Colors.white54, fontSize: 16,
            letterSpacing: 1));
  }
}
