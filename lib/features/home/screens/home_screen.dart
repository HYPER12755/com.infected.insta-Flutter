import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/bottom_nav_provider.dart';
import '../../feed/screens/feed_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../reels/screens/reels_screen.dart';
import '../../search/screens/search_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);

    final screens = [
      const FeedScreen(),
      const SearchScreen(),
      const ReelsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
