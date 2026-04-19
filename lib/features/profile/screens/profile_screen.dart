import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:infected_insta/features/profile/providers/profile_provider.dart';
import 'package:infected_insta/features/settings/presentation/settings_screen.dart';
import 'package:infected_insta/features/create_post/providers/storage_provider.dart';
import 'package:infected_insta/supabase/supabase_client.dart';
import 'package:infected_insta/data/repositories/message_repository.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId; // null = own profile
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwn = userId == null;
    final state = isOwn
        ? ref.watch(profileProvider)
        : ref.watch(userProfileProvider(userId!));

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.white54, size: 40),
          const SizedBox(height: 16),
          Text(state.error ?? 'Error', style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: () => isOwn
              ? ref.read(profileProvider.notifier).load()
              : ref.read(userProfileProvider(userId!).notifier).load(),
              child: const Text('Retry')),
        ])),
      );
    }

    final user = state.user!;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: RefreshIndicator(
        onRefresh: () => isOwn
            ? ref.read(profileProvider.notifier).load()
            : ref.read(userProfileProvider(userId!).notifier).load(),
        color: primaryColor,
        child: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                floating: true,
                backgroundColor: const Color(0xFF0D0D1A),
                title: Text(user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                actions: [
                  if (isOwn) ...[
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.squarePlus, size: 22),
                      onPressed: () => context.push('/create'),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.bars, size: 20),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ],
              ),

              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      // Avatar
                      GestureDetector(
                        onTap: isOwn ? () => _changeAvatar(context, ref) : null,
                        child: Stack(children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFF2A2A3E),
                            backgroundImage: user.avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(user.avatarUrl) as ImageProvider
                                : null,
                            child: user.avatarUrl.isEmpty
                                ? const FaIcon(FontAwesomeIcons.user, size: 36, color: Colors.white54)
                                : null,
                          ),
                          if (isOwn)
                            Positioned(bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0D0D1A), width: 2),
                                  ),
                                  child: const FaIcon(FontAwesomeIcons.plus, size: 10, color: Colors.white),
                                )),
                        ]),
                      ),
                      const SizedBox(width: 20),
                      // Stats
                      Expanded(child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statCol(user.posts.toString(), 'Posts', null),
                          _statCol(_fmt(user.followers), 'Followers',
                              () => context.push('/followers/${user.userId}?username=${user.username}')),
                          _statCol(_fmt(user.following), 'Following',
                              () => context.push('/following/${user.userId}?username=${user.username}')),
                        ],
                      )),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (user.name.isNotEmpty)
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (user.bio.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 4),
                            child: Text(user.bio, style: const TextStyle(fontSize: 13))),
                      if (user.website.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () => Clipboard.setData(
                                ClipboardData(text: user.website)).then((_) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)))),
                            child: Text(user.website,
                                style: const TextStyle(
                                    color: Color(0xFF5B8FDE),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: isOwn
                        ? Row(children: [
                            Expanded(child: _ghostBtn('Edit Profile',
                                () => context.push('/profile/edit'))),
                            const SizedBox(width: 8),
                            Expanded(child: _ghostBtn('Share Profile', () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile link copied!')));
                            })),
                          ])
                        : _buildFollowRow(context, ref, user.userId, primaryColor),
                  ),

                  // Story highlights
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/story-create'),
                          child: _highlightItem(primaryColor, 'New', Icons.add)),
                        GestureDetector(
                          onTap: () => context.push('/highlights'),
                          child: _highlightItem(primaryColor, 'All', Icons.play_circle_outline)),
                      ],
                    ),
                  ),
                ]),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(),
              ),
            ],
            body: TabBarView(children: [
              _PostGrid(posts: state.posts),
              _TaggedGrid(userId: user.userId),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    final storage = SupabaseStorageService(supabase);
    final path = 'avatars/$uid/${const Uuid().v4()}.jpg';
    try {
      final url = await storage.uploadFile(file.path, path, bucket: 'avatars');
      await ref.read(profileProvider.notifier).updateProfile(
        fullName: ref.read(profileProvider).user?.name ?? '',
        username: ref.read(profileProvider).user?.username ?? '',
        bio: ref.read(profileProvider).user?.bio ?? '',
        avatarUrl: url,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update avatar: $e')));
      }
    }
  }

  Widget _buildFollowRow(BuildContext context, WidgetRef ref, String targetId, Color primary) {
    final state = ref.watch(userProfileProvider(targetId));
    final isFollowing = state.isFollowing;
    return Row(children: [
      Expanded(child: ElevatedButton(
        onPressed: () async {
          final uid = supabase.auth.currentUser?.id;
          if (uid == null) return;
          final notifier = ref.read(userProfileProvider(targetId).notifier);
          if (isFollowing) {
            await notifier.unfollowUser(targetId);
          } else {
            await notifier.followUser(targetId);
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? const Color(0xFF2A2A3E) : primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(isFollowing ? 'Following' : 'Follow'),
      )),
      const SizedBox(width: 8),
      Expanded(child: _ghostBtn('Message', () async {
        final uid = supabase.auth.currentUser?.id;
        if (uid == null) return;
        final repo = MessageRepository();
        final result = await repo.getOrCreateConversation(uid, targetId);
        result.fold((_) {}, (convId) {
          if (context.mounted) {
            context.push('/chat/$convId');
          }
        });
      })),
      const SizedBox(width: 8),
      _ghostBtn('', () => _showUserOptions(context, ref, targetId, isFollowing), icon: FontAwesomeIcons.chevronDown),
    ]);
  }

  void _showUserOptions(BuildContext context, WidgetRef ref, String targetId, bool isFollowing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        if (isFollowing) ListTile(
          leading: const FaIcon(FontAwesomeIcons.userMinus, color: Colors.redAccent),
          title: const Text('Unfollow', style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            Navigator.pop(context);
            await ref.read(userProfileProvider(targetId).notifier).unfollowUser(targetId);
          },
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.ban),
          title: const Text('Block'),
          onTap: () async {
            Navigator.pop(context);
            final uid = supabase.auth.currentUser?.id;
            if (uid != null) {
              await supabase.from('blocks').upsert({
                'blocker_id': uid, 'blocked_id': targetId,
                'created_at': DateTime.now().toIso8601String(),
              });
            }
            if (context.mounted) context.go('/home');
          },
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.flag),
          title: const Text('Report'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('User reported. Thank you.')));
          },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap, {FaIconData? icon}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      child: icon != null
          ? FaIcon(icon, size: 14, color: Colors.white)
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _statCol(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _highlightItem(Color primary, String label, IconData icon) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60, height: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white54),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ]);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _PostGrid extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  const _PostGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FaIcon(FontAwesomeIcons.imagePortrait, size: 48, color: Colors.white24),
        SizedBox(height: 12),
        Text('No posts yet', style: TextStyle(color: Colors.white38)),
      ]));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final imageUrl = posts[i]['image_url'] ?? posts[i]['imageUrl'] ?? '';
        return GestureDetector(
          onTap: () => context.push('/post/${posts[i]['id']}'),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: const Color(0xFF2A2A3E)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF2A2A3E),
                    child: const FaIcon(FontAwesomeIcons.image, color: Colors.white24),
                  ),
                )
              : Container(color: const Color(0xFF2A2A3E)),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.grid_on)),
          Tab(icon: Icon(Icons.person_pin_outlined)),
        ],
        indicatorColor: Color(0xFFC039FF),
        unselectedLabelColor: Colors.white38,
      ),
    );
  }

  @override double get maxExtent => 48;
  @override double get minExtent => 48;
  @override bool shouldRebuild(_) => false;
}

// ─── Tagged Posts Grid (real DB data) ────────────────────────────────────────
class _TaggedGrid extends StatefulWidget {
  final String userId;
  const _TaggedGrid({required this.userId});
  @override
  State<_TaggedGrid> createState() => _TaggedGridState();
}

class _TaggedGridState extends State<_TaggedGrid> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await supabase
          .from('post_tags')
          .select('post_id, posts(id, image_url)')
          .eq('tagged_user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['posts'] as Map<String, dynamic>? ?? {};
            return {'id': p['id'], 'imageUrl': p['image_url'] ?? ''};
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemCount: 9,
        itemBuilder: (_, __) => Container(color: const Color(0xFF2A2A3E)),
      );
    }
    if (_posts.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.userTag, size: 44, color: Colors.white24),
          SizedBox(height: 12),
          Text('No tagged posts yet', style: TextStyle(color: Colors.white38)),
        ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: _posts.length,
      itemBuilder: (context, i) {
        final url = _posts[i]['imageUrl'] as String? ?? '';
        return GestureDetector(
          onTap: () => context.push('/post/${_posts[i]['id']}'),
          child: url.isNotEmpty
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: const Color(0xFF2A2A3E)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A3E)))
              : Container(color: const Color(0xFF2A2A3E)),
        );
      },
    );
  }
}
