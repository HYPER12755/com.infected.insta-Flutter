import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:infected_insta/features/chat/screens/chat_screen.dart';
import 'package:infected_insta/features/search/screens/explore_screen.dart';
import 'package:infected_insta/features/create_post/screens/create_screens.dart';
import 'package:infected_insta/features/reels/screens/reels_screen.dart';
import 'package:infected_insta/features/profile/screens/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Premium Home Page with glassmorphism bottom navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  final _pages = [
    const _FeedTab(),
    const ExploreScreen(),
    const CreatePostScreen(),
    const ReelsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

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
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                _navItem(3, FontAwesomeIcons.play, 'Reels'),
                _navItem(4, FontAwesomeIcons.comment, 'Messages'),
                _navItem(5, FontAwesomeIcons.user, 'Profile'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
      onTap: () {
        setState(() => _currentIndex = 2);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const FaIcon(
          FontAwesomeIcons.plus,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Interactive Feed Tab with full post interactions
class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab();

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  final List<Map<String, dynamic>> _posts = List.generate(10, (index) {
    return {
      'id': index,
      'username': _mockUsernames[index % _mockUsernames.length],
      'userAvatar': 'https://i.pravatar.cc/150?img=${index + 1}',
      'location': _mockLocations[index % _mockLocations.length],
      'imageUrl': 'https://picsum.photos/seed/post$index/400/500',
      'caption': _mockCaptions[index % _mockCaptions.length],
      'likes': (index + 1) * 127,
      'comments': (index + 1) * 23,
      'time': '${(index + 1) * 2}h',
      'isLiked': false,
      'isSaved': false,
    };
  });

  static const _mockUsernames = [
    'sarah_designs',
    'mike_travels',
    'foodie_jane',
    'tech_guru',
    'fitness_pro',
    'artsy_alex',
    'music_lover',
    'travel_bug',
    'photo_king',
    'fashion_first',
  ];

  static const _mockLocations = [
    'New York, USA',
    'Tokyo, Japan',
    'Paris, France',
    'London, UK',
    'Sydney, Australia',
    'Los Angeles, USA',
    'Berlin, Germany',
    'Toronto, Canada',
    'Milan, Italy',
    'Barcelona, Spain',
  ];

  static const _mockCaptions = [
    'Living my best life! ✨ #blessed #livingmybestlife',
    'Adventure awaits! 🌎 Who else loves traveling?',
    'Food is life 🍕 What should I eat next?',
    'Just launched something amazing! Check it out 🚀',
    'Workout complete! 💪 Who is with me?',
    'Art is everywhere 🎨 Found this gem today',
    'Music is my therapy 🎵 What are you listening to?',
    'Wanderlust ✈️ Where to next?',
    'Capture the moment 📸 Love this view!',
    'Style game strong 👗 Fashion week vibes',
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFC039FF), Color(0xFF9B59B6)],
              ).createShader(bounds),
              child: const Text(
                'Infected',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.bell, size: 20),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 20),
                onPressed: () => context.push('/messages'),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildStories(primaryColor)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildPost(_posts[i], primaryColor, i),
              childCount: _posts.length,
            ),
          ),
          // Loading indicator for infinite scroll
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories(Color primaryColor) {
    final stories = List.generate(8, (index) {
      return {
        'id': index,
        'username': index == 0 ? 'your_story' : _mockUsernames[index - 1],
        'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
        'hasStory': index != 0,
        'isViewed': index > 3,
      };
    });

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (ctx, index) =>
            _storyItem(stories[index], primaryColor, index),
      ),
    );
  }

  Widget _storyItem(Map<String, dynamic> story, Color primaryColor, int index) {
    final bool isYourStory = story['username'] == 'your_story';
    final bool hasStory = story['hasStory'];
    final bool isViewed = story['isViewed'];

    return GestureDetector(
      onTap: () {
        if (isYourStory) {
          context.push('/story-create');
        } else {
          context.push(
            '/story/${story['id']}',
            extra: {
              'username': story['username'],
              'avatar': story['avatar'],
              'images': List.generate(
                3,
                (i) => 'https://picsum.photos/seed/${story['id']}_$i/400/700',
              ),
            },
          );
        }
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: hasStory && !isViewed
                    ? const LinearGradient(
                        colors: [Color(0xFFC039FF), Color(0xFF9B59B6)],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1A1A2E),
                backgroundImage: CachedNetworkImageProvider(story['avatar']),
                child: isYourStory
                    ? const FaIcon(
                        FontAwesomeIcons.plus,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isYourStory ? 'Your Story' : story['username'],
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post, Color primaryColor, int index) {
    final bool isLiked = post['isLiked'];
    final bool isSaved = post['isSaved'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            context.push('/profile/${post['username']}'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: CachedNetworkImageProvider(
                            post['userAvatar'],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  context.push('/profile/${post['username']}'),
                              child: Text(
                                post['username'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (post['location'].isNotEmpty)
                              Text(
                                post['location'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.ellipsis, size: 18),
                        onPressed: () => _showPostOptions(context, index),
                      ),
                    ],
                  ),
                ),
                // Image
                GestureDetector(
                  onDoubleTap: () => _toggleLike(index),
                  onDoubleTapCancel: () {},
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: post['imageUrl'],
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 400,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 400,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Icon(Icons.error),
                        ),
                      ),
                      // Heart animation overlay when liking
                      if (isLiked)
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 80,
                        ),
                    ],
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Like button
                          GestureDetector(
                            onTap: () => _toggleLike(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FaIcon(
                                isLiked
                                    ? FontAwesomeIcons.solidHeart
                                    : FontAwesomeIcons.heart,
                                size: 24,
                                color: isLiked ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Comment button
                          GestureDetector(
                            onTap: () => _showComments(context, post['id']),
                            child: const FaIcon(
                              FontAwesomeIcons.comment,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Share button
                          GestureDetector(
                            onTap: () => _sharePost(post),
                            child: const FaIcon(
                              FontAwesomeIcons.paperPlane,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          // Save button
                          GestureDetector(
                            onTap: () => _toggleSave(index),
                            child: FaIcon(
                              isSaved
                                  ? FontAwesomeIcons.solidBookmark
                                  : FontAwesomeIcons.bookmark,
                              size: 22,
                              color: isSaved ? primaryColor : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Likes count
                      Text(
                        '${_formatCount(post['likes'])} likes',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Caption
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: post['username'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: ' ${post['caption']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // View comments
                      GestureDetector(
                        onTap: () => _showComments(context, post['id']),
                        child: Text(
                          'View all ${post['comments']} comments',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Time
                      Text(
                        post['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      _posts[index]['isLiked'] = !_posts[index]['isLiked'];
      if (_posts[index]['isLiked']) {
        _posts[index]['likes'] = (_posts[index]['likes'] as int) + 1;
      } else {
        _posts[index]['likes'] = (_posts[index]['likes'] as int) - 1;
      }
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _posts[index]['isSaved'] = !_posts[index]['isSaved'];
    });
    final isSaved = _posts[index]['isSaved'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? 'Post saved to collections' : 'Post removed from saved',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComments(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(postId: postId),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.paperPlane),
              title: const Text('Send to followers'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to followers!')),
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.message),
              title: const Text('Send as message'),
              onTap: () {
                Navigator.pop(context);
                context.push('/new-message');
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.link),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.bookmark),
              title: const Text('Save'),
              onTap: () {
                Navigator.pop(context);
                _toggleSave(index);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.link),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied!')));
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.share),
              title: const Text('Share to...'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(_posts[index]);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.flag),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Post reported')));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Comments Sheet - Full implementation
class _CommentsSheet extends StatefulWidget {
  final int postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = List.generate(5, (index) {
    return {
      'id': index,
      'username': _mockCommenters[index % _mockCommenters.length],
      'avatar': 'https://i.pravatar.cc/150?img=${index + 20}',
      'comment': _mockComments[index % _mockComments.length],
      'likes': index * 7,
      'isLiked': false,
      'time': '${index + 1}h',
    };
  });

  static const _mockCommenters = [
    'fan_123',
    'comment_king',
    'social_butterfly',
    'daily_poster',
    'viewer_99',
  ];
  static const _mockComments = [
    'This is amazing! 🔥',
    'Love this! ❤️',
    'So cool! 😎',
    'Great content! 👏',
    'Amazing! ✨',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.paperPlane),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Comments list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) => _buildComment(_comments[index]),
            ),
          ),
          // Comment input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final bool isLiked = comment['isLiked'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: CachedNetworkImageProvider(comment['avatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: comment['username'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${comment['comment']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      comment['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          comment['isLiked'] = !comment['isLiked'];
                          comment['likes'] = comment['isLiked']
                              ? comment['likes'] + 1
                              : comment['likes'] - 1;
                        });
                      },
                      child: Text(
                        '${comment['likes']} likes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                comment['isLiked'] = !comment['isLiked'];
                comment['likes'] = comment['isLiked']
                    ? comment['likes'] + 1
                    : comment['likes'] - 1;
              });
            },
            child: FaIcon(
              isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              size: 14,
              color: isLiked ? Colors.red : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFC039FF),
              child: FaIcon(FontAwesomeIcons.user, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.paperPlane,
                color: _commentController.text.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Colors.white.withValues(alpha: 0.5),
              ),
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  setState(() {
                    _comments.insert(0, {
                      'id': _comments.length,
                      'username': 'you',
                      'avatar': 'https://i.pravatar.cc/150?img=1',
                      'comment': _commentController.text,
                      'likes': 0,
                      'isLiked': false,
                      'time': 'now',
                    });
                  });
                  _commentController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
