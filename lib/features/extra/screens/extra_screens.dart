import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

// ─── Saved Posts Screen ───────────────────────────────────────────────────────
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _isLoading = false); return; }

    try {
      final res = await supabase
          .from('saved_posts')
          .select('post_id, posts(id, image_url, caption, user_id, '
              'profiles!posts_user_id_fkey(username))')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['posts'] as Map<String, dynamic>? ?? {};
            return {
              'id': p['id'],
              'imageUrl': p['image_url'] ?? '',
              'caption': p['caption'] ?? '',
              'username': ((p['profiles'] as Map<String, dynamic>?)?['username']) ?? 'user',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PostGridScreen(
    title: 'Saved',
    posts: _posts,
    isLoading: _isLoading,
    emptyIcon: FontAwesomeIcons.bookmark,
    emptyMessage: 'Save photos and videos',
    emptySubtitle: 'Save photos and videos that you want to see again. No one is notified.',
  );
}

// ─── Archive Screen ───────────────────────────────────────────────────────────
class ArchiveViewScreen extends StatefulWidget {
  const ArchiveViewScreen({super.key});

  @override
  State<ArchiveViewScreen> createState() => _ArchiveViewScreenState();
}

class _ArchiveViewScreenState extends State<ArchiveViewScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _isLoading = false); return; }

    try {
      final res = await supabase
          .from('posts')
          .select('id, image_url, caption')
          .eq('user_id', uid)
          .eq('is_archived', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = (res as List).map<Map<String, dynamic>>((p) => {
            'id': p['id'],
            'imageUrl': p['image_url'] ?? '',
            'caption': p['caption'] ?? '',
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PostGridScreen(
    title: 'Archive',
    posts: _posts,
    isLoading: _isLoading,
    emptyIcon: FontAwesomeIcons.archive,
    emptyMessage: 'Archive posts',
    emptySubtitle: 'Archived posts are only visible to you.',
  );
}

// ─── Tagged Posts Screen ──────────────────────────────────────────────────────
class TaggedPostsScreen extends StatefulWidget {
  const TaggedPostsScreen({super.key});

  @override
  State<TaggedPostsScreen> createState() => _TaggedPostsScreenState();
}

class _TaggedPostsScreenState extends State<TaggedPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _isLoading = false); return; }

    try {
      final res = await supabase
          .from('post_tags')
          .select('post_id, posts(id, image_url, caption)')
          .eq('tagged_user_id', uid)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['posts'] as Map<String, dynamic>? ?? {};
            return {
              'id': p['id'],
              'imageUrl': p['image_url'] ?? '',
              'caption': p['caption'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PostGridScreen(
    title: 'Tagged',
    posts: _posts,
    isLoading: _isLoading,
    emptyIcon: FontAwesomeIcons.userTag,
    emptyMessage: 'Photos of You',
    emptySubtitle: 'When people tag you in photos, they\'ll appear here.',
  );
}

// ─── Followers / Following List Screen ───────────────────────────────────────
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String username;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.username,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      List<dynamic> res;
      if (widget.type == 'followers') {
        res = await supabase
            .from('follows')
            .select('follower_id, profiles!follows_follower_id_fkey(id, username, avatar_url, full_name)')
            .eq('following_id', widget.userId);
      } else {
        res = await supabase
            .from('follows')
            .select('following_id, profiles!follows_following_id_fkey(id, username, avatar_url, full_name)')
            .eq('follower_id', widget.userId);
      }

      final myId = supabase.auth.currentUser?.id;

      if (mounted) {
        setState(() {
          _users = res.map<Map<String, dynamic>>((r) {
            final key = widget.type == 'followers' ? 'profiles' : 'profiles';
            final p = (r[key] as Map<String, dynamic>?) ?? {};
            return {
              'id': p['id'],
              'username': p['username'] ?? 'user',
              'avatar': p['avatar_url'] ?? '',
              'name': p['full_name'] ?? p['username'] ?? '',
              'isMe': p['id'] == myId,
              'isFollowing': false, // check asynchronously if needed
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(int i) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final user = _users[i];
    final was = user['isFollowing'] as bool;
    setState(() => _users[i]['isFollowing'] = !was);

    if (!was) {
      await supabase.from('follows').upsert(
          {'follower_id': uid, 'following_id': user['id']});
    } else {
      await supabase.from('follows').delete()
          .match({'follower_id': uid, 'following_id': user['id']});
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final title = widget.type == 'followers' ? 'Followers' : 'Following';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text('${widget.username} — $title'),
      ),
      body: _isLoading
          ? ListView.builder(itemCount: 6,
              itemBuilder: (_, __) => const UserTileSkeleton())
          : _users.isEmpty
              ? Center(child: Text('No $title yet',
                  style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final avatar = u['avatar'] as String? ?? '';
                    final isMe = u['isMe'] == true;
                    final isFollowing = u['isFollowing'] == true;

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () => context.push('/profile/${u['username']}'),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF2A2A3E),
                          backgroundImage: avatar.isNotEmpty
                              ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
                          child: avatar.isEmpty
                              ? Text((u['username'] as String? ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white)) : null,
                        ),
                      ),
                      title: Text(u['username'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: u['name'] != u['username'] && (u['name'] as String).isNotEmpty
                          ? Text(u['name'] ?? '',
                              style: const TextStyle(color: Colors.white54))
                          : null,
                      trailing: isMe
                          ? null
                          : GestureDetector(
                              onTap: () => _toggleFollow(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isFollowing
                                      ? const Color(0xFF2A2A3E) : primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(isFollowing ? 'Following' : 'Follow',
                                    style: TextStyle(
                                      color: isFollowing ? Colors.white54 : Colors.white,
                                      fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ),
                      onTap: () => context.push('/profile/${u['username']}'),
                    );
                  },
                ),
    );
  }
}

// ─── Shared Post Grid Screen ──────────────────────────────────────────────────
class _PostGridScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final FaIconData emptyIcon;
  final String emptyMessage;
  final String emptySubtitle;

  const _PostGridScreen({
    required this.title,
    required this.posts,
    required this.isLoading,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text(title),
      ),
      body: isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: 9,
              itemBuilder: (_, __) => const GridItemSkeleton())
          : posts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(emptyIcon, size: 48, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(emptyMessage,
                        style: const TextStyle(color: Colors.white70,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(emptySubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35))),
                    ),
                  ]))
              : GridView.builder(
                  padding: const EdgeInsets.all(1),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                  itemCount: posts.length,
                  itemBuilder: (_, i) {
                    final imageUrl = posts[i]['imageUrl'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => context.push('/post/${posts[i]['id']}'),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                              placeholder: (_, __) => const GridItemSkeleton(),
                              errorWidget: (_, __, ___) =>
                                  Container(color: const Color(0xFF2A2A3E)))
                          : Container(color: const Color(0xFF2A2A3E)),
                    );
                  },
                ),
    );
  }
}


