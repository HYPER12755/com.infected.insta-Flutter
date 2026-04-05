import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Explore Grid Screen - 3-column image grid like Instagram
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Mock data for explore grid
  final List<Map<String, dynamic>> _exploreItems = List.generate(30, (index) {
    return {
      'id': index,
      'type': index % 5 == 0 ? 'reel' : 'post',
      'likes': '${(index * 1234).clamp(100, 999999)}',
    };
  });

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _isSearching = value.isNotEmpty);
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, color: InstagramColors.darkTextSecondary),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: InstagramColors.darkTextSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _isSearching = false);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: InstagramColors.darkSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildExploreGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Recent Searches
        const Text(
          'Recent',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: InstagramColors.darkText,
          ),
        ),
        const SizedBox(height: 16),
        // Recent search items
        ...List.generate(5, (index) => _buildRecentSearchItem(index)),
        const SizedBox(height: 24),
        // Suggested
        const Text(
          'Suggested',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: InstagramColors.darkText,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(8, (index) => _buildUserResult(index)),
      ],
    );
  }

  Widget _buildRecentSearchItem(int index) {
    return ListTile(
      leading: const Icon(Icons.history, color: InstagramColors.darkTextSecondary),
      title: Text(
        'Recent search ${index + 1}',
        style: const TextStyle(color: InstagramColors.darkText),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: InstagramColors.darkTextSecondary),
      onTap: () {},
    );
  }

  Widget _buildUserResult(int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: InstagramColors.primary,
        child: Text('U${index + 1}'),
      ),
      title: Text(
        'user_${index + 1}',
        style: const TextStyle(color: InstagramColors.darkText, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'User ${index + 1}',
        style: const TextStyle(color: InstagramColors.darkTextSecondary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 20, color: InstagramColors.darkTextSecondary),
        onPressed: () {},
      ),
    );
  }

  Widget _buildExploreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _exploreItems.length,
      itemBuilder: (context, index) {
        final item = _exploreItems[index];
        return _buildGridItem(index, item);
      },
    );
  }

  Widget _buildGridItem(int index, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (item['type'] == 'reel') {
          // Open reel
        } else {
          // Open post
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder image
          Container(
            color: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.3),
            child: Center(
              child: Icon(
                item['type'] == 'reel' ? Icons.play_arrow : Icons.image,
                color: Colors.white.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
          ),
          // Reel icon overlay
          if (item['type'] == 'reel')
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
          // Likes overlay on hover/tap
          Positioned(
            bottom: 4,
            left: 4,
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 12),
                const SizedBox(width: 2),
                Text(
                  item['likes'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trending Tags Screen
class TrendingTagsScreen extends StatelessWidget {
  const TrendingTagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trendingTags = [
      {'tag': 'photography', 'posts': '2.3M'},
      {'tag': 'travel', 'posts': '5.1M'},
      {'tag': 'food', 'posts': '8.2M'},
      {'tag': 'fashion', 'posts': '4.7M'},
      {'tag': 'art', 'posts': '3.9M'},
      {'tag': 'fitness', 'posts': '2.8M'},
      {'tag': 'nature', 'posts': '6.4M'},
      {'tag': 'music', 'posts': '7.1M'},
    ];

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: InstagramColors.darkBackground,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trendingTags.length,
        itemBuilder: (context, index) {
          final tag = trendingTags[index];
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: InstagramColors.instagramGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tag, color: Colors.white),
            ),
            title: Text(
              '#${tag['tag']}',
              style: const TextStyle(
                color: InstagramColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${tag['posts']} posts',
              style: const TextStyle(color: InstagramColors.darkTextSecondary),
            ),
            onTap: () {
              // Navigate to tag posts
            },
          );
        },
      ),
    );
  }
}

/// User Search Results Screen
class UserSearchResultsScreen extends StatelessWidget {
  final String query;

  const UserSearchResultsScreen({super.key, required this.query});

  // Mock users based on search query
  List<Map<String, dynamic>> get _users {
    return List.generate(10, (index) {
      return {
        'id': index,
        'username': '${query}_user_$index',
        'name': 'User $index',
        'avatar': null,
        'isFollowing': index % 3 == 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: Text('Results for "$query"', style: const TextStyle(color: InstagramColors.darkText)),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: InstagramColors.primary,
              child: Text(
                user['username'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user['username'],
              style: const TextStyle(color: InstagramColors.darkText, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user['name'],
              style: const TextStyle(color: InstagramColors.darkTextSecondary),
            ),
            trailing: user['isFollowing']
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: InstagramColors.darkSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Following', style: TextStyle(color: InstagramColors.darkTextSecondary, fontSize: 12)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: InstagramColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Follow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
            onTap: () {},
          );
        },
      ),
    );
  }
}