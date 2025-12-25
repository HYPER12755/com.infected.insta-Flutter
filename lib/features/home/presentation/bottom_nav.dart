import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/features/home/presentation/home_screen.dart';
import 'package:myapp/features/profile/presentation/profile_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // Your existing home screen
    const Center(child: Text('Search')),
    const Center(child: Text('Add Post')),
    const Center(child: Text('Video')),
    const ProfileScreen(), // The new profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF100E10),
        selectedItemColor: const Color(0xFFC039FF),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add Post',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.video),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFC039FF), // Use a placeholder or actual user image
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Color(0xFF100E10),
                child: Icon(Icons.person, size: 20, color: Color(0xFFC039FF)),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
