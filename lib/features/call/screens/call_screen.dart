import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/call/models/call_model.dart';
import 'package:myapp/features/call/providers/call_provider.dart';
import 'package:myapp/features/call/screens/video_call_screen.dart';

/// Screen for incoming and outgoing call UI
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

    // Show incoming call dialog if there's an incoming call
    if (callState.hasIncomingCall && callState.incomingCall != null) {
      return _IncomingCallScreen(incomingCall: callState.incomingCall!);
    }

    // Show outgoing call screen if we have callee info
    if (calleeId != null && calleeName != null) {
      return _OutgoingCallScreen(
        calleeId: calleeId!,
        calleeName: calleeName!,
        calleeAvatar: calleeAvatar,
        callType: callType ?? CallType.video,
      );
    }

    // Default - show call dial pad or user selection
    return const _CallInitScreen();
  }
}

/// Screen for initiating a call (select user and call type)
class _CallInitScreen extends ConsumerStatefulWidget {
  const _CallInitScreen();

  @override
  ConsumerState<_CallInitScreen> createState() => _CallInitScreenState();
}

class _CallInitScreenState extends ConsumerState<_CallInitScreen> {
  CallType _selectedCallType = CallType.video;
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserAvatar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Call')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Call type selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallTypeButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  isSelected: _selectedCallType == CallType.video,
                  onTap: () =>
                      setState(() => _selectedCallType = CallType.video),
                ),
                const SizedBox(width: 16),
                _CallTypeButton(
                  icon: Icons.call,
                  label: 'Audio',
                  isSelected: _selectedCallType == CallType.audio,
                  onTap: () =>
                      setState(() => _selectedCallType = CallType.audio),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // User selection placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a user to call',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _selectedUserId != null
                          ? () => _startCall(context)
                          : null,
                      icon: Icon(
                        _selectedCallType == CallType.video
                            ? Icons.videocam
                            : Icons.call,
                      ),
                      label: Text(
                        _selectedCallType == CallType.video
                            ? 'Start Video Call'
                            : 'Start Audio Call',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCall(BuildContext context) {
    // TODO: Implement user selection UI
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please implement user selection UI'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Call type selection button widget
class _CallTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CallTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for outgoing call (dialing)
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
  ConsumerState<_OutgoingCallScreen> createState() =>
      _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<_OutgoingCallScreen> {
  @override
  void initState() {
    super.initState();
    // Start the call when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCall();
    });
  }

  Future<void> _startCall() async {
    final success = await ref
        .read(callProvider.notifier)
        .makeCall(
          calleeId: widget.calleeId,
          calleeName: widget.calleeName,
          calleeAvatar: widget.calleeAvatar,
          callType: widget.callType,
        );

    if (success && mounted) {
      // Navigate to video call screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const VideoCallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.primaryColor.withAlpha(77),
              child: Text(
                widget.calleeName.isNotEmpty
                    ? widget.calleeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              widget.calleeName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Status
            Text(
              callState.isConnecting
                  ? 'Calling...'
                  : callState.error ?? 'Unknown error',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withAlpha(178),
              ),
            ),
            const Spacer(),
            // Call type icon
            Icon(
              widget.callType == CallType.video ? Icons.videocam : Icons.call,
              size: 32,
              color: Colors.white.withAlpha(178),
            ),
            const SizedBox(height: 16),
            // Cancel button
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton(
                onPressed: () {
                  ref.read(callProvider.notifier).endCall();
                  Navigator.of(context).pop();
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for incoming call
class _IncomingCallScreen extends ConsumerWidget {
  final CallModel incomingCall;

  const _IncomingCallScreen({required this.incomingCall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isVideoCall = incomingCall.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.primaryColor.withAlpha(77),
              child: Text(
                incomingCall.callerName.isNotEmpty
                    ? incomingCall.callerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              incomingCall.callerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Call type
            Text(
              isVideoCall ? 'Incoming video call' : 'Incoming audio call',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withAlpha(178),
              ),
            ),
            const Spacer(),
            // Call type icon
            Icon(
              isVideoCall ? Icons.videocam : Icons.call,
              size: 32,
              color: Colors.white.withAlpha(178),
            ),
            const SizedBox(height: 32),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  FloatingActionButton(
                    onPressed: () {
                      ref.read(callProvider.notifier).declineCall();
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  // Accept button
                  FloatingActionButton(
                    onPressed: () async {
                      final success = await ref
                          .read(callProvider.notifier)
                          .acceptCall();
                      if (success && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const VideoCallScreen(),
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
