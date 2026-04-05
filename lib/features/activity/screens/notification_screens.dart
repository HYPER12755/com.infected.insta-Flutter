import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Activity Feed Screen
class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock activities
    final activities = [
      {
        'type': 'like',
        'user': 'user_1',
        'action': 'liked your post',
        'time': '2h',
        'avatar': 'U1',
      },
      {
        'type': 'follow',
        'user': 'user_2',
        'action': 'started following you',
        'time': '4h',
        'avatar': 'U2',
      },
      {
        'type': 'comment',
        'user': 'user_3',
        'action': 'commented: "Amazing! 🔥"',
        'time': '5h',
        'avatar': 'U3',
      },
      {
        'type': 'like',
        'user': 'user_4',
        'action': 'liked your reel',
        'time': '6h',
        'avatar': 'U4',
      },
      {
        'type': 'follow',
        'user': 'user_5',
        'action': 'started following you',
        'time': '1d',
        'avatar': 'U5',
      },
      {
        'type': 'mention',
        'user': 'user_6',
        'action': 'mentioned you in a post',
        'time': '1d',
        'avatar': 'U6',
      },
      {
        'type': 'like',
        'user': 'user_7',
        'action': 'liked your story',
        'time': '2d',
        'avatar': 'U7',
      },
    ];

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
      body: ListView.separated(
        itemCount: activities.length,
        separatorBuilder: (context, index) =>
            const Divider(color: InstagramColors.darkSecondary, height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(activity);
        },
      ),
    );
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
    final requests = [
      {'id': 1, 'username': 'user_request_1', 'time': '2h ago'},
      {'id': 2, 'username': 'user_request_2', 'time': '5h ago'},
      {'id': 3, 'username': 'user_request_3', 'time': '1d ago'},
    ];

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
                    child: Text(req['username']?.toString().isNotEmpty == true ? req['username'].toString()[13].toUpperCase() : '?'),
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
  late List<Map<String, dynamic>> _interactions;

  @override
  void initState() {
    super.initState();
    // Mock data
    if (widget.type == 'likes') {
      _interactions = List.generate(15, (index) {
        return {
          'id': index,
          'username': 'user_liked_$index',
          'isFollowing': index < 5,
        };
      });
    } else {
      _interactions = List.generate(10, (index) {
        return {
          'id': index,
          'username': 'user_commented_$index',
          'comment': 'Great post! 🔥',
          'time': '${index + 1}h',
        };
      });
    }
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
        child: Text(item['username']?.toString().isNotEmpty == true ? item['username'].toString()[10].toUpperCase() : '?'),
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
        child: Text(item['username']?.toString().isNotEmpty == true ? item['username'].toString()[13].toUpperCase() : '?'),
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
