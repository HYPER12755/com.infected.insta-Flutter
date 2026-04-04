import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/call/models/call_model.dart';
import 'package:myapp/features/call/providers/call_provider.dart';

/// Active video/audio call screen with controls
class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  Timer? _callTimer;
  int _callDuration = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final callProviderNotifier = ref.read(callProvider.notifier);
    final theme = Theme.of(context);

    // Check if call is still active
    if (!callState.isInCall || callState.currentCall == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    final call = callState.currentCall!;
    final isVideoCall = call.callType == CallType.video;
    final isCaller = call.isCaller(callProviderNotifier.currentUserId ?? '');

    // Determine the other party's name
    final otherPartyName = isCaller ? call.calleeName : call.callerName;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Remote video or placeholder
            Positioned.fill(
              child: isVideoCall
                  ? _VideoView(
                      renderer: callProviderNotifier.remoteRenderer,
                      placeholder: otherPartyName,
                    )
                  : _AudioCallPlaceholder(name: otherPartyName),
            ),

            // Local video (picture-in-picture)
            if (isVideoCall && callState.isVideoEnabled)
              Positioned(
                top: 60,
                right: 16,
                width: 100,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _VideoView(
                    renderer: callProviderNotifier.localRenderer,
                    placeholder: null,
                  ),
                ),
              ),

            // Top bar with call info
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(178), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Call type icon
                      Icon(
                        isVideoCall ? Icons.videocam : Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Name and duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherPartyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDuration(_callDuration),
                              style: TextStyle(
                                color: Colors.white.withAlpha(178),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(77),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                    top: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(178), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _ControlButton(
                        icon: callState.isAudioEnabled
                            ? Icons.mic
                            : Icons.mic_off,
                        label: callState.isAudioEnabled ? 'Mute' : 'Unmute',
                        isActive: !callState.isAudioEnabled,
                        onPressed: () {
                          callProviderNotifier.toggleAudio();
                        },
                      ),

                      // End call button
                      _ControlButton(
                        icon: Icons.call_end,
                        label: 'End',
                        isActive: true,
                        isEndCall: true,
                        onPressed: () {
                          callProviderNotifier.endCall();
                          Navigator.of(context).pop();
                        },
                      ),

                      // Video toggle (only for video calls)
                      if (isVideoCall)
                        _ControlButton(
                          icon: callState.isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: callState.isVideoEnabled
                              ? 'Stop Video'
                              : 'Start Video',
                          isActive: !callState.isVideoEnabled,
                          onPressed: () {
                            callProviderNotifier.toggleVideo();
                          },
                        )
                      else
                        const SizedBox(width: 64),

                      // Switch camera (only for video calls)
                      if (isVideoCall)
                        _ControlButton(
                          icon: Icons.cameraswitch,
                          label: 'Flip',
                          onPressed: () {
                            callProviderNotifier.switchCamera();
                          },
                        )
                      else
                        const SizedBox(width: 64),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Video view widget with renderer and placeholder
class _VideoView extends StatelessWidget {
  final dynamic renderer;
  final String? placeholder;

  const _VideoView({required this.renderer, this.placeholder});

  @override
  Widget build(BuildContext context) {
    if (renderer != null && renderer.srcObject != null) {
      // Use RTCVideoRenderer view
      return Texture(textureId: renderer.textureId);
    }

    // Placeholder when no video
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: placeholder != null
            ? Text(
                placeholder![0].toUpperCase(),
                style: const TextStyle(fontSize: 64, color: Colors.white54),
              )
            : const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
      ),
    );
  }
}

/// Audio call placeholder widget
class _AudioCallPlaceholder extends StatelessWidget {
  final String name;

  const _AudioCallPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withAlpha(77),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Audio Call',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isEndCall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    if (isEndCall) {
      backgroundColor = Colors.red;
      iconColor = Colors.white;
    } else if (isActive) {
      backgroundColor = Colors.white.withAlpha(51);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withAlpha(26);
      iconColor = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 12),
        ),
      ],
    );
  }
}
