import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/features/search/screens/explore_screen.dart';
import 'package:infected_insta/features/create_post/screens/create_screens.dart';
import 'package:infected_insta/features/reels/screens/reels_screen.dart';
import 'package:infected_insta/features/profile/screens/profile_screen.dart';
import 'package:infected_insta/supabase/supabase_client.dart';
import 'package:infected_insta/core/widgets/rich_caption.dart';

// Unread notification count provider
final _unreadCountProvider = StreamProvider<int>((ref) {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return Stream.value(0);
  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .map((rows) => rows.where((r) => r['is_read'] != true).length);
});

// DM unread count — purple dot on paper-plane icon
final _unreadDmCountProvider = StreamProvider<int>((ref) {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return Stream.value(0);
  // Stream conversations where last_sender is not us and there are unread messages
  return supabase
      .from('conversations')
      .stream(primaryKey: ['id'])
      .map((rows) => rows
          .where((r) =>
              r['last_sender_id'] != null &&
              r['last_sender_id'] != uid &&
              (r['last_message'] as String? ?? '').isNotEmpty &&
              (r['participant_ids'] as List?)?.contains(uid) == true)
          .length);
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      _FeedTab(),       // 0 Home
      ExploreScreen(),  // 1 Search
      CreatePostScreen(),// 2 Create (centre +)
      ReelsScreen(),    // 3 Reels
      ProfileScreen(),  // 4 Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      extendBody: true,
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, FontAwesomeIcons.house, 'Home'),
                _navItem(1, FontAwesomeIcons.magnifyingGlass, 'Search'),
                _addButton(),
                _navItem(3, FontAwesomeIcons.film, 'Reels'),
                _navItem(4, FontAwesomeIcons.user, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, FaIconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const FaIcon(FontAwesomeIcons.plus, size: 18, color: Colors.white),
      ),
    );
  }
}

// ─── Feed Tab ──────────────────────────────────────────────────────────────────

class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab();
  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  final PostRepository _postRepo = PostRepository();
  final UserRepository _userRepo = UserRepository();

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int? _heartBurstIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMorePosts();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadPosts(), _loadStories()]);
  }

  Future<void> _loadStories() async {
    try {
      // Load active stories (not expired) from followed users + own
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;

      final res = await supabase
          .from('stories')
          .select('id, image_url, user_id, created_at, profiles!stories_user_id_fkey(username, avatar_url)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;

      // Group by user, keep latest story per user
      final Map<String, Map<String, dynamic>> byUser = {};
      for (final row in (res as List)) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? {};
        final userId = row['user_id'] as String? ?? '';
        if (!byUser.containsKey(userId)) {
          byUser[userId] = {
            'id': row['id'],
            'user_id': userId,
            'image_url': row['image_url'],
            'username': profile['username'] ?? 'user',
            'avatar_url': profile['avatar_url'] ?? '',
          };
        }
      }

      setState(() => _stories = byUser.values.toList());
    } catch (_) {}
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    final result = await _postRepo.getPosts();
    if (!mounted) return;

    result.fold(
      (err) => setState(() { _error = err.message; _isLoading = false; }),
      (posts) {
        final uid = supabase.auth.currentUser?.id;
        setState(() {
          _posts = posts.map((p) => {
            ...p,
            'isLiked': false,
            'isSaved': false,
            '_uid': uid,
          }).toList();
          _isLoading = false;
        });
        // check real like status asynchronously
        _checkLikeStatuses(uid);
      },
    );
  }

  Future<void> _checkLikeStatuses(String? uid) async {
    if (uid == null) return;
    // Batch: fetch liked + saved post IDs for current user
    try {
      final likedRes = await supabase
          .from('post_likes').select('post_id').eq('user_id', uid);
      final savedRes = await supabase
          .from('saved_posts').select('post_id').eq('user_id', uid);
      final likedIds = (likedRes as List).map((r) => r['post_id'] as String).toSet();
      final savedIds = (savedRes as List).map((r) => r['post_id'] as String).toSet();
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _posts.length; i++) {
          final id = _posts[i]['id']?.toString() ?? '';
          _posts[i]['isLiked'] = likedIds.contains(id);
          _posts[i]['isSaved'] = savedIds.contains(id);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadMorePosts() async {
    if (_posts.isEmpty) return;
    setState(() => _isLoadingMore = true);
    final lastId = _posts.last['id']?.toString();
    final result = await _postRepo.getPostsPaginated(lastDoc: lastId, limit: 10);
    result.fold((_) {}, (more) {
      if (mounted) {
        setState(() {
          _posts.addAll(more.map((p) => {...p, 'isLiked': false, 'isSaved': false}));
        });
      }
    });
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final postId = post['id']?.toString();
    final uid = supabase.auth.currentUser?.id;
    if (postId == null || uid == null) return;

    final wasLiked = post['isLiked'] as bool;
    // optimistic update
    setState(() {
      _posts[index]['isLiked'] = !wasLiked;
      _posts[index]['likes'] = ((_posts[index]['likes'] as int?) ?? 0) + (wasLiked ? -1 : 1);
    });
    HapticFeedback.lightImpact();

    final result = wasLiked
        ? await _postRepo.unlikePost(postId, uid)
        : await _postRepo.likePost(postId, uid);

    result.fold((err) {
      // revert on failure
      if (mounted) {
        setState(() {
          _posts[index]['isLiked'] = wasLiked;
          _posts[index]['likes'] = ((_posts[index]['likes'] as int?) ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    }, (_) {});
  }

  Future<void> _toggleSave(int index) async {
    final post = _posts[index];
    final postId = post['id']?.toString();
    final uid = supabase.auth.currentUser?.id;
    if (postId == null || uid == null) return;

    final wasSaved = post['isSaved'] as bool;
    setState(() => _posts[index]['isSaved'] = !wasSaved);
    HapticFeedback.selectionClick();

    final result = wasSaved
        ? await _postRepo.unsavePost(postId, uid)
        : await _postRepo.savePost(postId, uid);

    result.fold((err) {
      if (mounted) setState(() => _posts[index]['isSaved'] = wasSaved);
    }, (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(wasSaved ? 'Removed from saved' : 'Saved to collection'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return SafeArea(child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text('Loading feed…', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        ]),
      ));
    }

    if (_error != null && _posts.isEmpty) {
      return SafeArea(child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Could not load feed', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadData, child: Text('Retry', style: TextStyle(color: primaryColor))),
        ]),
      ));
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFC039FF), Color(0xFF9B59B6)],
                ).createShader(b),
                child: const Text('Infected',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              actions: [
                // Notifications
                Consumer(builder: (ctx, ref, _) {
                  final count = ref.watch(_unreadCountProvider).valueOrNull ?? 0;
                  return Stack(clipBehavior: Clip.none, children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.bell, size: 22),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (count > 0)
                      Positioned(top: 8, right: 8,
                        child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                        )),
                  ]);
                }),
                // Direct Messages — top-right, Instagram style
                Consumer(builder: (ctx, ref, _) {
                  final unread = ref.watch(_unreadDmCountProvider).valueOrNull ?? 0;
                  return Stack(clipBehavior: Clip.none, children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 22),
                      onPressed: () => context.push('/messages'),
                    ),
                    if (unread > 0)
                      Positioned(top: 8, right: 8,
                        child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(
                              color: Color(0xFFC039FF), shape: BoxShape.circle),
                        )),
                  ]);
                }),
                const SizedBox(width: 4),
              ],
            ),

            SliverToBoxAdapter(child: _buildStories(primaryColor)),

            if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FaIcon(FontAwesomeIcons.imagePortrait, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No posts yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    Text('Follow people to see their posts', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildPost(_posts[i], primaryColor, i),
                  childCount: _posts.length,
                ),
              ),

            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStories(Color primaryColor) {
    final allStories = [
      {'id': 'your_story', 'username': 'Your Story', 'avatar_url': null, 'isYours': true},
      ..._stories.map((s) => {...s, 'isYours': false}),
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: allStories.length,
        itemBuilder: (ctx, i) => _storyItem(allStories[i], primaryColor),
      ),
    );
  }

  Widget _storyItem(Map<String, dynamic> story, Color primaryColor) {
    final isYours = story['isYours'] == true;
    final avatar = story['avatar_url'] as String?;
    final username = story['username'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        if (isYours) {
          context.push('/story-create');
        } else {
          final imageUrl = story['image_url'] as String? ?? '';
          context.push('/story/${story['user_id']}', extra: {
            'username': username,
            'avatar': avatar ?? '',
            'userId': story['user_id'] ?? '',
            'images': imageUrl.isNotEmpty ? <String>[imageUrl] : <String>[],
          });
        }
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              gradient: isYours
                  ? null
                  : const LinearGradient(colors: [Color(0xFFC039FF), Color(0xFF9B59B6)]),
              color: isYours ? Colors.white.withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(25),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1A1A2E),
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? CachedNetworkImageProvider(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? FaIcon(isYours ? FontAwesomeIcons.plus : FontAwesomeIcons.user,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isYours ? 'Your Story' : username,
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post, Color primaryColor, int index) {
    final bool isLiked = post['isLiked'] == true;
    final bool isSaved = post['isSaved'] == true;
    final imageUrl = post['imageUrl'] as String? ?? '';
    final username = post['username'] as String? ?? 'unknown';
    final userAvatar = post['userAvatar'] as String? ?? '';
    final caption = post['caption'] as String? ?? '';
    final location = post['location'] as String? ?? '';
    final likes = (post['likes'] as int?) ?? 0;
    final commentsCount = (post['commentsCount'] as int?) ?? 0;
    final postId = post['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/$username'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF2A2A3E),
                      backgroundImage: (userAvatar.isNotEmpty)
                          ? CachedNetworkImageProvider(userAvatar) as ImageProvider
                          : null,
                      child: userAvatar.isEmpty
                          ? const FaIcon(FontAwesomeIcons.user, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/$username'),
                        child: Text(username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      if (location.isNotEmpty)
                        Text(location,
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                    ]),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.ellipsis, size: 16),
                    onPressed: () => _showPostOptions(context, index),
                  ),
                ]),
              ),

              // ── Image ──
              if (imageUrl.isNotEmpty)
                GestureDetector(
                  onDoubleTap: () {
                    _toggleLike(index);
                    setState(() => _heartBurstIndex = index);
                    Future.delayed(const Duration(milliseconds: 900),
                        () { if (mounted) setState(() => _heartBurstIndex = null); });
                  },
                  child: Stack(alignment: Alignment.center, children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 380,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 380,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 380,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Center(child: FaIcon(FontAwesomeIcons.image, color: Colors.white24, size: 48)),
                      ),
                    ),
                    if (_heartBurstIndex == index)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        builder: (_, v, __) => Opacity(
                          opacity: v < 0.5 ? v * 2 : (1 - v) * 2,
                          child: Transform.scale(
                            scale: 0.5 + v * 0.8,
                            child: const FaIcon(FontAwesomeIcons.solidHeart,
                                color: Colors.white, size: 90),
                          ),
                        ),
                      ),
                  ]),
                ),

              // ── Actions ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => _toggleLike(index),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: FaIcon(
                          key: ValueKey(isLiked),
                          isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                          size: 24,
                          color: isLiked ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showComments(context, postId),
                      child: const FaIcon(FontAwesomeIcons.comment, size: 22),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _sharePost(post),
                      child: const FaIcon(FontAwesomeIcons.paperPlane, size: 22),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleSave(index),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: FaIcon(
                          key: ValueKey(isSaved),
                          isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                          size: 22,
                          color: isSaved ? primaryColor : Colors.white,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (likes > 0)
                    Text('${_fmtCount(likes)} likes',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichCaption(username: username, caption: caption),
                  ],
                  if (commentsCount > 0) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showComments(context, postId),
                      child: Text('View all $commentsCount comments',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(_fmtTime(post['created_at']),
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
                  const SizedBox(height: 8),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showComments(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: postId),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Text('Share', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white12),
        ListTile(leading: const FaIcon(FontAwesomeIcons.message),
            title: const Text('Send as message'),
            onTap: () { Navigator.pop(context); context.push('/new-message'); }),
        ListTile(leading: const FaIcon(FontAwesomeIcons.link),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: 'https://infected.app/post/${post['id']}'));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)));
            }),
      ])),
    );
  }

  void _showPostOptions(BuildContext context, int index) {
    final uid = supabase.auth.currentUser?.id;
    final isOwn = _posts[index]['user_id'] == uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        ListTile(leading: const FaIcon(FontAwesomeIcons.bookmark),
            title: Text(_posts[index]['isSaved'] == true ? 'Remove from saved' : 'Save'),
            onTap: () { Navigator.pop(context); _toggleSave(index); }),
        ListTile(leading: const FaIcon(FontAwesomeIcons.link),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: 'https://infected.app/post/${_posts[index]['id']}'));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)));
            }),
        if (!isOwn)
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.eyeSlash),
            title: const Text('Not interested'),
            onTap: () {
              Navigator.pop(context);
              if (mounted) setState(() => _posts.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You'll see fewer posts like this')));
            },
          ),
        if (isOwn)
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
            title: const Text('Delete post', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final postId = _posts[index]['id']?.toString() ?? '';
              await _postRepo.deletePost(postId);
              if (mounted) setState(() => _posts.removeAt(index));
            },
          )
        else
          ListTile(leading: const FaIcon(FontAwesomeIcons.flag),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported. Thank you.')));
              }),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.link),
          title: const Text('Copy link'),
          onTap: () {
            Navigator.pop(context);
            final postId = _posts[index]['id']?.toString() ?? '';
            Clipboard.setData(ClipboardData(text: 'https://infected.app/post/$postId'));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)));
          },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  String _fmtCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return 'just now';
    DateTime t;
    if (raw is DateTime) {
      t = raw;
    } else if (raw is String) {
      t = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      return 'just now';
    }
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'just now';
  }
}

// ─── Comments Sheet ─────────────────────────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});
  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final PostRepository _postRepo = PostRepository();
  final UserRepository _userRepo = UserRepository();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _replyingTo = '';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final result = await _postRepo.getComments(widget.postId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoading = false),
      (c) => setState(() { _comments = c; _isLoading = false; }),
    );
  }

  Future<void> _sendComment() async {
    final raw = _commentCtrl.text.trim();
    final text = _replyingTo.isNotEmpty ? '@$_replyingTo $raw' : raw;
    if (raw.isEmpty || _isSending) return;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _isSending = true);
    _commentCtrl.clear();

    final result = await _postRepo.addComment(
        postId: widget.postId, userId: uid, text: text);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isSending = false),
        (comment) => setState(() {
          _comments.add(comment);
          _isSending = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            GestureDetector(onTap: () => Navigator.pop(context),
                child: const FaIcon(FontAwesomeIcons.xmark)),
          ]),
        ),
        const Divider(color: Colors.white12, height: 1),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _comments.isEmpty
                  ? Center(child: Text('No comments yet. Be first!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _buildComment(_comments[i]),
                    ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: SafeArea(child: Row(children: [
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFFC039FF),
                child: FaIcon(FontAwesomeIcons.user, size: 13)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _replyingTo.isNotEmpty ? 'Replying to @$_replyingTo…' : 'Add a comment…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
            _isSending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: FaIcon(FontAwesomeIcons.paperPlane,
                        color: _commentCtrl.text.isNotEmpty
                            ? Theme.of(context).primaryColor
                            : Colors.white.withValues(alpha: 0.3)),
                    onPressed: _sendComment,
                  ),
          ])),
        ),
      ]),
    );
  }

  Widget _buildComment(Map<String, dynamic> c) {
    final avatar = c['avatar'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF2A2A3E),
          backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
          child: avatar.isEmpty ? const FaIcon(FontAwesomeIcons.user, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: '${c['username'] ?? ''} ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            TextSpan(text: c['text'] ?? c['comment'] ?? '',
                style: const TextStyle(fontSize: 13)),
          ])),
          const SizedBox(height: 4),
          Text(_fmtTime(c['created_at']),
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        ])),
      ]),
    );
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return 'just now';
    DateTime t = raw is String ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'just now';
  }
}
