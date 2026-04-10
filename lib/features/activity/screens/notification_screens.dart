import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/data/fixtures/mock_requests_data.dart';
import 'package:infected_insta/data/repositories/notification_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';

/// Activity Feed Screen
class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationRepo = NotificationRepository();
    final userRepo = UserRepository();
    final currentUserId = userRepo.getCurrentUserId();

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'Please sign in to view notifications',
                style: TextStyle(color: InstagramColors.darkText),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: notificationRepo
                  .getNotifications(currentUserId)
                  .map(
                    (result) => result.fold(
                      (error) => <Map<String, dynamic>>[],
                      (notifications) => notifications,
                    ),
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: InstagramColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: InstagramColors.darkText,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: TextStyle(
                            color: InstagramColors.darkText.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: InstagramColors.darkText.withValues(
                            alpha: 0.5,
                          ),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: InstagramColors.darkText.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Convert Firestore notifications to UI format
                final activities = notifications.map((notification) {
                  return _convertNotificationToActivity(notification);
                }).toList();

                return _buildActivityListView(activities);
              },
            ),
    );
  }

  Widget _buildMockListView(List<Map<String, dynamic>> activities) {
    return ListView.separated(
      itemCount: activities.length,
      separatorBuilder: (context, index) =>
          const Divider(color: InstagramColors.darkSecondary, height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityListView(List<Map<String, dynamic>> activities) {
    return ListView.separated(
      itemCount: activities.length,
      separatorBuilder: (context, index) =>
          const Divider(color: InstagramColors.darkSecondary, height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Map<String, dynamic> _convertNotificationToActivity(
    Map<String, dynamic> notification,
  ) {
    final type = notification['type'] as String? ?? 'like';
    final fromUsername = notification['fromUsername'] as String? ?? 'User';
    final createdAt = notification['createdAt'];

    // Calculate time ago
    String timeAgo = 'Just now';
    if (createdAt != null) {
      final now = DateTime.now();
      DateTime notificationTime;
      if (createdAt is DateTime) {
        notificationTime = createdAt;
      } else {
        // Handle Timestamp from Firestore
        notificationTime = DateTime.now(); // Fallback
      }
      final difference = now.difference(notificationTime);

      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        timeAgo = '${difference.inDays}d';
      } else {
        timeAgo = '${difference.inDays ~/ 7}w';
      }
    }

    String action;
    switch (type) {
      case 'like':
        action = 'liked your post';
        break;
      case 'follow':
        action = 'started following you';
        break;
      case 'comment':
        action = 'commented on your post';
        break;
      case 'mention':
        action = 'mentioned you in a post';
        break;
      default:
        action = 'interacted with you';
    }

    // Get avatar initial
    final avatarInitial = fromUsername.isNotEmpty
        ? fromUsername[0].toUpperCase()
        : 'U';

    return {
      'type': type,
      'user': fromUsername,
      'action': action,
      'time': timeAgo,
      'avatar': avatarInitial,
      'isRead': notification['isRead'] ?? false,
    };
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color iconColor;

    switch (activity['type']) {
      case 'like':
        icon = Icons.favorite;
        iconColor = InstagramColors.red;
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = InstagramColors.secondary;
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        iconColor = InstagramColors.primary;
        break;
      case 'mention':
        icon = Icons.alternate_email;
        iconColor = InstagramColors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = InstagramColors.darkTextSecondary;
    }

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: InstagramColors.primary,
            child: Text(
              activity['avatar'],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: InstagramColors.darkBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: iconColor),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: activity['user'],
              style: const TextStyle(
                color: InstagramColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' ${activity['action']}',
              style: const TextStyle(color: InstagramColors.darkText),
            ),
          ],
        ),
      ),
      subtitle: Text(
        activity['time'],
        style: const TextStyle(
          color: InstagramColors.darkTextSecondary,
          fontSize: 12,
        ),
      ),
      trailing: _buildActivityPreview(activity['type']),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildActivityPreview(String type) {
    switch (type) {
      case 'like':
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: InstagramColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.favorite_border,
            size: 20,
            color: InstagramColors.red,
          ),
        );
      case 'follow':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: InstagramColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Follow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      default:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: InstagramColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }
}

/// Follow Requests Screen
class FollowRequestsScreen extends StatelessWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock requests
    final requests = MockRequestsData.followRequestsList;

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Follow Requests',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${requests.length} pending requests',
                  style: const TextStyle(
                    color: InstagramColors.darkTextSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Clear all')),
              ],
            ),
          ),
          // Requests list
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: InstagramColors.primary,
                    child: Text(
                      req['username']?.toString().isNotEmpty == true
                          ? req['username'].toString()[13].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    req['username']?.toString() ?? '',
                    style: const TextStyle(
                      color: InstagramColors.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    req['time']?.toString() ?? '',
                    style: const TextStyle(
                      color: InstagramColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Confirm button
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: InstagramColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: InstagramColors.darkSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: InstagramColors.darkText,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Likes/Comments Detail Screen
class LikesCommentsScreen extends StatefulWidget {
  final String type; // 'likes' or 'comments'
  final String postId;

  const LikesCommentsScreen({
    super.key,
    required this.type,
    required this.postId,
  });

  @override
  State<LikesCommentsScreen> createState() => _LikesCommentsScreenState();
}

class _LikesCommentsScreenState extends State<LikesCommentsScreen> {
  List<Map<String, dynamic>> _interactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // No mock data - empty list for production
    _interactions = [];
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: Text(
          widget.type == 'likes' ? 'Likes' : 'Comments',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.builder(
        itemCount: _interactions.length,
        itemBuilder: (context, index) {
          final item = _interactions[index];
          if (widget.type == 'likes') {
            return _buildLikeItem(item);
          } else {
            return _buildCommentItem(item);
          }
        },
      ),
    );
  }

  Widget _buildLikeItem(Map<String, dynamic> item) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: InstagramColors.primary,
        child: Text(
          item['username']?.toString().isNotEmpty == true
              ? item['username'].toString()[10].toUpperCase()
              : '?',
        ),
      ),
      title: Text(
        item['username']?.toString() ?? '',
        style: const TextStyle(
          color: InstagramColors.darkText,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: item['isFollowing']
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: InstagramColors.darkSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Following',
                style: TextStyle(
                  color: InstagramColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: InstagramColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> item) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: InstagramColors.primary,
        child: Text(
          item['username']?.toString().isNotEmpty == true
              ? item['username'].toString()[13].toUpperCase()
              : '?',
        ),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: item['username']?.toString() ?? '',
              style: const TextStyle(
                color: InstagramColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: item['comment']?.toString() ?? '',
              style: const TextStyle(color: InstagramColors.darkText),
            ),
          ],
        ),
      ),
      subtitle: Text(
        item['time'],
        style: const TextStyle(
          color: InstagramColors.darkTextSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
