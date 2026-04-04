import 'package:flutter/material.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';

/// Button widget to initiate a call from profile or chat
class CallButton extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final CallType callType;
  final double size;

  const CallButton({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.callType = CallType.video,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () => _showCallOptions(context),
      icon: Icon(
        callType == CallType.video ? Icons.videocam : Icons.call,
        color: theme.colorScheme.primary,
        size: size,
      ),
      tooltip: callType == CallType.video ? 'Video call' : 'Audio call',
    );
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CallOptionsSheet(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
      ),
    );
  }
}

/// Call options bottom sheet
class _CallOptionsSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const _CallOptionsSheet({
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withAlpha(77),
                backgroundImage: userAvatar != null
                    ? NetworkImage(userAvatar!)
                    : null,
                child: userAvatar == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Start a call',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Call options
          Row(
            children: [
              Expanded(
                child: _CallOptionButton(
                  icon: Icons.videocam,
                  label: 'Video Call',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _startCall(context, CallType.video);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CallOptionButton(
                  icon: Icons.call,
                  label: 'Audio Call',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _startCall(context, CallType.audio);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _startCall(BuildContext context, CallType callType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          calleeId: userId,
          calleeName: userName,
          calleeAvatar: userAvatar,
          callType: callType,
        ),
      ),
    );
  }
}

/// Individual call option button
class _CallOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
