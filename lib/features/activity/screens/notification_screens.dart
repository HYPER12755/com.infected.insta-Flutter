import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/data/repositories/notification_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

// ─── Activity Feed Screen ─────────────────────────────────────────────────────
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _notifRepo = NotificationRepository();
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _markAllRead();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    final uid = _userRepo.getCurrentUserId();
    if (uid != null) await _notifRepo.markAllAsRead(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userRepo.getCurrentUserId();

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.checkDouble, size: 18),
            tooltip: 'Mark all read',
            onPressed: _markAllRead,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFC039FF),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Follow Requests'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text('Sign in to see notifications', style: TextStyle(color: Colors.white54)),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _NotificationList(userId: uid, repo: _notifRepo),
                FollowRequestsScreen(embedded: true),
              ],
            ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final String userId;
  final NotificationRepository repo;

  const _NotificationList({required this.userId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo
          .getNotifications(userId)
          .map((r) => r.fold((_) => <Map<String, dynamic>>[], (n) => n)),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ListView.builder(itemCount: 6, itemBuilder: (_, __) => const UserTileSkeleton());
        }

        final notifs = snap.data ?? [];

        if (notifs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.bell, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                const Text(
                  'No activity yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'When people like or comment on your posts, you\'ll see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Group by time
        final today = <Map<String, dynamic>>[];
        final thisWeek = <Map<String, dynamic>>[];
        final earlier = <Map<String, dynamic>>[];

        for (final n in notifs) {
          final t = DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
          final d = DateTime.now().difference(t);
          if (d.inHours < 24) {
            today.add(n);
          } else if (d.inDays < 7)
            thisWeek.add(n);
          else
            earlier.add(n);
        }

        return ListView(
          children: [
            if (today.isNotEmpty) ...[
              _header('Today'),
              ...today.map((n) => _NotificationTile(notif: n)),
            ],
            if (thisWeek.isNotEmpty) ...[
              _header('This Week'),
              ...thisWeek.map((n) => _NotificationTile(notif: n)),
            ],
            if (earlier.isNotEmpty) ...[
              _header('Earlier'),
              ...earlier.map((n) => _NotificationTile(notif: n)),
            ],
          ],
        );
      },
    );
  }

  Widget _header(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final type = notif['type'] as String? ?? 'like';
    final actor = notif['actor_username'] as String? ?? 'someone';
    final actorAvatar = notif['actor_avatar'] as String? ?? '';
    final postImage = notif['post_image'] as String? ?? '';
    final isRead = notif['is_read'] == true;

    FaIconData icon;
    Color iconColor;
    String message;

    switch (type) {
      case 'like':
        icon = FontAwesomeIcons.solidHeart;
        iconColor = Colors.red;
        message = 'liked your photo.';
        break;
      case 'comment':
        icon = FontAwesomeIcons.comment;
        iconColor = const Color(0xFFC039FF);
        message = 'commented: "${notif['comment_text'] ?? ''}"';
        break;
      case 'follow':
        icon = FontAwesomeIcons.userPlus;
        iconColor = Colors.blue;
        message = 'started following you.';
        break;
      case 'mention':
        icon = FontAwesomeIcons.at;
        iconColor = Colors.orange;
        message = 'mentioned you in a comment.';
        break;
      default:
        icon = FontAwesomeIcons.bell;
        iconColor = Colors.white;
        message = notif['message'] as String? ?? '';
    }

    return Container(
      color: isRead ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2A2A3E),
              backgroundImage: actorAvatar.isNotEmpty
                  ? NetworkImage(actorAvatar) as ImageProvider
                  : null,
              child: actorAvatar.isEmpty
                  ? Text(
                      actor.isNotEmpty ? actor[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                child: FaIcon(icon, size: 8, color: Colors.white),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$actor ',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextSpan(
                text: message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        subtitle: Text(
          _fmtTime(notif['created_at']),
          style: const TextStyle(color: InstagramColors.darkTextSecondary, fontSize: 11),
        ),
        trailing: postImage.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(postImage, width: 44, height: 44, fit: BoxFit.cover),
              )
            : (type == 'follow'
                  ? _FollowBackBtn(userId: notif['actor_id'] as String? ?? '')
                  : null),
        onTap: () {
          if (notif['post_id'] != null) {
            context.push('/post/${notif['post_id']}');
          } else if (type == 'follow') {
            context.push('/profile/$actor');
          }
        },
      ),
    );
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return 'now';
    final t = raw is String ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}

class _FollowBackBtn extends StatefulWidget {
  final String userId;
  const _FollowBackBtn({required this.userId});

  @override
  State<_FollowBackBtn> createState() => _FollowBackBtnState();
}

class _FollowBackBtnState extends State<_FollowBackBtn> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () async {
        final uid = supabase.auth.currentUser?.id;
        if (uid == null) return;
        setState(() => _following = !_following);
        HapticFeedback.lightImpact();
        if (_following) {
          await supabase.from('follows').upsert({
            'follower_id': uid,
            'following_id': widget.userId,
          });
        } else {
          await supabase.from('follows').delete().match({
            'follower_id': uid,
            'following_id': widget.userId,
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _following ? InstagramColors.darkSurface : primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _following ? 'Following' : 'Follow Back',
          style: TextStyle(
            color: _following ? Colors.white60 : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Follow Requests Screen ───────────────────────────────────────────────────
class FollowRequestsScreen extends StatefulWidget {
  final bool embedded;
  const FollowRequestsScreen({super.key, this.embedded = false});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await supabase
          .from('follow_requests')
          .select(
            'id, requester_id, profiles!follow_requests_requester_id_fkey(username, avatar_url)',
          )
          .eq('target_id', uid)
          .eq('status', 'pending');

      if (mounted) {
        setState(() {
          _requests = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return {
              'id': r['id'],
              'userId': r['requester_id'],
              'username': p['username'] ?? 'user',
              'avatar': p['avatar_url'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(int i, bool accept) async {
    final req = _requests[i];
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _requests.removeAt(i));

    try {
      await supabase
          .from('follow_requests')
          .update({'status': accept ? 'accepted' : 'rejected'})
          .eq('id', req['id']);

      if (accept) {
        await supabase.from('follows').upsert({'follower_id': req['userId'], 'following_id': uid});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? ListView.builder(itemCount: 4, itemBuilder: (_, __) => const UserTileSkeleton())
        : _requests.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.userClock, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('No follow requests', style: TextStyle(color: Colors.white54)),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _requests.length,
            itemBuilder: (_, i) {
              final r = _requests[i];
              final avatar = r['avatar'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2A2A3E),
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) as ImageProvider : null,
                  child: avatar.isEmpty ? const FaIcon(FontAwesomeIcons.user, size: 14) : null,
                ),
                title: Text(
                  r['username'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _respond(i, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC039FF),
                          borderRadius: BorderRadius.circular(6),
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
                    GestureDetector(
                      onTap: () => _respond(i, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => context.push('/profile/${r['username']}'),
              );
            },
          );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Follow Requests'),
      ),
      body: content,
    );
  }
}
