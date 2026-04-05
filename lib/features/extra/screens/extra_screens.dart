import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Close Friends Screen - Manage close friends list
class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> {
  // Mock close friends
  final List<Map<String, dynamic>> _friends = List.generate(15, (index) {
    return {
      'id': index,
      'username': 'friend_$index',
      'avatar': null,
      'isAdded': index < 5, // First 5 are added
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Close Friends',
          style: TextStyle(color: InstagramColors.darkText),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choose who to add to your close friends list. Only your close friends will see your story at the top of their feed.',
              style: TextStyle(
                color: InstagramColors.darkTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: InstagramColors.primary,
                    child: Text(
                      friend['username'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    friend['username'],
                    style: const TextStyle(
                      color: InstagramColors.darkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: friend['isAdded']
                          ? InstagramColors.primary
                          : InstagramColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        friend['isAdded'] ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Toggle friend
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Guides Screen - Collection/Guides feature
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Guides',
          style: TextStyle(color: InstagramColors.darkText),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: InstagramColors.darkText),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: InstagramColors.darkTextSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No guides yet',
              style: TextStyle(
                color: InstagramColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Save posts and create guides\nthat you can share',
              textAlign: TextAlign.center,
              style: TextStyle(color: InstagramColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shop Screen - Instagram Shop feature
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Shop',
          style: TextStyle(color: InstagramColors.darkText),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: InstagramColors.darkText,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategory('All', true),
                _buildCategory('Curated', false),
                _buildCategory('Mens', false),
                _buildCategory('Womens', false),
                _buildCategory('Kids', false),
                _buildCategory('Electronics', false),
              ],
            ),
          ),
          // Products grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: InstagramColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: InstagramColors.darkSecondary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: InstagramColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product $index',
                              style: const TextStyle(
                                color: InstagramColors.darkText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${(index + 1) * 10}',
                              style: const TextStyle(
                                color: InstagramColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildCategory(String name, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? InstagramColors.primary
            : InstagramColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : InstagramColors.darkTextSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Live Stream Screen
class LiveStreamScreen extends StatelessWidget {
  const LiveStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live video placeholder
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_outlined, size: 80, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'Go Live',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to start a live video',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text('0 watching', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Comment...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.share, color: Colors.white, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Map Explore Screen - Location based posts
class MapExploreScreen extends StatelessWidget {
  const MapExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Explore',
          style: TextStyle(color: InstagramColors.darkText),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: InstagramColors.darkTextSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Explore Map',
              style: TextStyle(
                color: InstagramColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Discover posts from\nplaces around you',
              textAlign: TextAlign.center,
              style: TextStyle(color: InstagramColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
