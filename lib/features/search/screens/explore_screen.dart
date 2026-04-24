import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  final _userRepo = UserRepository();
  final _postRepo = PostRepository();

  bool _isSearching = false;
  bool _isLoadingPosts = true;
  bool _isLoadingSearch = false;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _recentSearches = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final result = await _postRepo.getPosts();
    if (mounted) {
      result.fold(
        (_) => setState(() => _isLoadingPosts = false),
        (posts) => setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        }),
      );
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _isLoadingSearch = true);

    final result = await _userRepo.searchUsers(query);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isLoadingSearch = false),
        (users) => setState(() {
          _searchResults = users;
          _isLoadingSearch = false;
        }),
      );
    }
  }

  void _addToHistory(Map<String, dynamic> user) {
    final exists = _recentSearches.any((u) => u['id'] == user['id']);
    if (!exists) {
      setState(() {
        _recentSearches.insert(0, user);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }
  }

  Future<void> _follow(String targetId, int index) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _searchResults[index]['isFollowing'] = true);
    try {
      await _userRepo.followUser(uid, targetId);
    } catch (_) {
      if (mounted) setState(() => _searchResults[index]['isFollowing'] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: SafeArea(child: Column(children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search people, hashtags…',
              hintStyle: const TextStyle(color: InstagramColors.darkTextSecondary),
              prefixIcon: const Icon(Icons.search, color: InstagramColors.darkTextSecondary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: InstagramColors.darkTextSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() { _isSearching = false; _searchResults = []; });
                      })
                  : null,
              filled: true,
              fillColor: InstagramColors.darkSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        Expanded(child: _isSearching
            ? _buildSearchResults(primary)
            : _buildExploreGrid()),
      ])),
    );
  }

  Widget _buildSearchResults(Color primary) {
    if (_isLoadingSearch) {
      return ListView.builder(itemCount: 6,
          itemBuilder: (_, __) => const UserTileSkeleton());
    }

    if (!_isLoadingSearch && _searchResults.isEmpty && _searchCtrl.text.isEmpty) {
      return _buildRecentSearches(primary);
    }

    if (_searchResults.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 40, color: Colors.white24),
        const SizedBox(height: 12),
        Text('No results for "${_searchCtrl.text}"',
            style: const TextStyle(color: Colors.white54)),
      ]));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _buildUserTile(_searchResults[i], i, primary),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index, Color primary) {
    final avatar = user['avatar_url'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final name = user['full_name'] as String? ?? username;
    final isFollowing = user['isFollowing'] == true;
    final userId = user['id'] as String? ?? '';

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _addToHistory(user);
          context.push('/profile/$username');
        },
        child: CircleAvatar(
          backgroundColor: const Color(0xFF2A2A3E),
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
          child: avatar.isEmpty
              ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white)) : null,
        ),
      ),
      title: GestureDetector(
        onTap: () {
          _addToHistory(user);
          context.push('/profile/$username');
        },
        child: Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      subtitle: Text(name, style: const TextStyle(color: InstagramColors.darkTextSecondary)),
      trailing: isFollowing
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: InstagramColors.darkSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Following',
                  style: TextStyle(color: InstagramColors.darkTextSecondary, fontSize: 12)),
            )
          : GestureDetector(
              onTap: () => _follow(userId, index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Follow',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
      onTap: () {
        _addToHistory(user);
        context.push('/profile/$username');
      },
    );
  }

  Widget _buildRecentSearches(Color primary) {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => setState(() => _recentSearches.clear()),
            child: const Text('Clear All'),
          ),
        ]),
      ),
      Expanded(child: ListView.builder(
        itemCount: _recentSearches.length,
        itemBuilder: (_, i) => _buildUserTile(_recentSearches[i], i, primary),
      )),
    ]);
  }

  Widget _buildExploreGrid() {
    if (_isLoadingPosts) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemCount: 9,
        itemBuilder: (_, __) => const GridItemSkeleton(),
      );
    }

    if (_posts.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const FaIcon(FontAwesomeIcons.compass, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        const Text('Nothing to explore yet', style: TextStyle(color: Colors.white38)),
      ]));
    }

    // Staggered 3-column grid with a featured large tile every 7 items
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(1),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate((_, i) {
            final post = _posts[i % _posts.length];
            final imageUrl = post['imageUrl'] as String? ?? '';
            return GestureDetector(
              onTap: () => context.push('/post/${post['id']}'),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const GridItemSkeleton(),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFF2A2A3E)),
                    )
                  : Container(color: const Color(0xFF2A2A3E),
                      child: const FaIcon(FontAwesomeIcons.image, color: Colors.white12)),
            );
          }, childCount: _posts.length),
        ),
      ),
    ]);
  }
}

// ─── Trending Tags Screen ─────────────────────────────────────────────────────
class TrendingTagsScreen extends StatefulWidget {
  const TrendingTagsScreen({super.key});

  @override
  State<TrendingTagsScreen> createState() => _TrendingTagsScreenState();
}

class _TrendingTagsScreenState extends State<TrendingTagsScreen> {
  List<Map<String, dynamic>> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Group posts by hashtags extracted from captions
      final res = await supabase
          .from('posts')
          .select('caption')
          .limit(200);

      final tagCounts = <String, int>{};
      for (final row in res as List) {
        final caption = row['caption'] as String? ?? '';
        final tags = RegExp(r'#(\w+)').allMatches(caption)
            .map((m) => m.group(1)!.toLowerCase());
        for (final t in tags) {
          tagCounts[t] = (tagCounts[t] ?? 0) + 1;
        }
      }

      final sorted = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _tags = sorted.take(20).map((e) => {
            'tag': e.key,
            'posts': e.value,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Trending'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? const Center(child: Text('No trending tags yet',
                  style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _tags.length,
                  itemBuilder: (_, i) {
                    final t = _tags[i];
                    return ListTile(
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('#', style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      title: Text('#${t['tag']}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${t['posts']} posts',
                          style: const TextStyle(color: InstagramColors.darkTextSecondary)),
                      onTap: () => context.push('/search/${t['tag']}'),
                    );
                  },
                ),
    );
  }
}

// ─── User Search Results Screen ───────────────────────────────────────────────
class UserSearchResultsScreen extends StatefulWidget {
  final String query;
  const UserSearchResultsScreen({super.key, required this.query});

  @override
  State<UserSearchResultsScreen> createState() => _UserSearchResultsScreenState();
}

class _UserSearchResultsScreenState extends State<UserSearchResultsScreen> {
  final _userRepo = UserRepository();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final result = await _userRepo.searchUsers(widget.query);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isLoading = false),
        (u) => setState(() { _users = u; _isLoading = false; }),
      );
    }
  }

  Future<void> _follow(int i) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _users[i]['isFollowing'] = true);
    try {
      await _userRepo.followUser(uid, _users[i]['id'] as String);
    } catch (_) {
      if (mounted) setState(() => _users[i]['isFollowing'] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text('Results for "${widget.query}"'),
      ),
      body: _isLoading
          ? ListView.builder(itemCount: 5,
              itemBuilder: (_, __) => const UserTileSkeleton())
          : _users.isEmpty
              ? const Center(child: Text('No users found',
                  style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final avatar = u['avatar_url'] as String? ?? '';
                    final username = u['username'] as String? ?? '';
                    final isFollowing = u['isFollowing'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2A2A3E),
                        backgroundImage: avatar.isNotEmpty
                            ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
                        child: avatar.isEmpty
                            ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white)) : null,
                      ),
                      title: Text(username,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u['full_name'] ?? username,
                          style: const TextStyle(color: InstagramColors.darkTextSecondary)),
                      trailing: isFollowing
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: InstagramColors.darkSurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Following',
                                  style: TextStyle(color: InstagramColors.darkTextSecondary,
                                      fontSize: 12)),
                            )
                          : GestureDetector(
                              onTap: () => _follow(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Follow',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ),
                      onTap: () => context.push('/profile/$username'),
                    );
                  },
                ),
    );
  }
}
