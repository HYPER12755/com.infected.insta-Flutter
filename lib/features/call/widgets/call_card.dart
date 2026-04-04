import 'package:flutter/material.dart';
import 'package:myapp/features/call/models/call_model.dart';
import 'package:intl/intl.dart';

/// Card widget for displaying call history items
class CallCard extends StatelessWidget {
  final CallModel call;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onCallAgain;

  const CallCard({
    super.key,
    required this.call,
    required this.currentUserId,
    this.onTap,
    this.onCallAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCaller = call.isCaller(currentUserId);
    final isMissed =
        call.status == CallStatus.declined ||
        (call.status == CallStatus.ringing && !isCaller);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primaryColor.withAlpha(77),
                  backgroundImage: isCaller && call.calleeAvatar != null
                      ? NetworkImage(call.calleeAvatar!)
                      : !isCaller && call.callerAvatar != null
                      ? NetworkImage(call.callerAvatar!)
                      : null,
                  child: isCaller
                      ? (call.calleeAvatar == null
                            ? Text(
                                call.calleeName.isNotEmpty
                                    ? call.calleeName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null)
                      : (call.callerAvatar == null
                            ? Text(
                                call.callerName.isNotEmpty
                                    ? call.callerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null),
                ),
                // Call type indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      call.callType == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      size: 12,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCaller ? call.calleeName : call.callerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isMissed ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Call direction indicator
                      Icon(
                        isCaller
                            ? (isMissed ? Icons.call_missed : Icons.call_made)
                            : (isMissed
                                  ? Icons.call_missed
                                  : Icons.call_received),
                        size: 14,
                        color: isMissed ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      // Time
                      Text(
                        _formatTime(call.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Call again button
            IconButton(
              onPressed: onCallAgain,
              icon: Icon(Icons.call, color: theme.colorScheme.primary),
              tooltip: 'Call again',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
