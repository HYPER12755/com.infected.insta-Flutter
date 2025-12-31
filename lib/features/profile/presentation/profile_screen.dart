import 'package:flutter/material.dart';
import 'package:myapp/features/profile/application/profile_provider.dart';
import 'package:myapp/features/profile/presentation/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;

        return Scaffold(
          appBar: AppBar(
            title: Text(profile.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.add_box_outlined)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
            ],
          ),
          body: DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: profile.profilePicture != null
                                    ? FileImage(profile.profilePicture!)
                                    : null,
                                child: profile.profilePicture == null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              _buildStatColumn('10', 'Posts'),
                              _buildStatColumn('1,234', 'Followers'),
                              _buildStatColumn('567', 'Following'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(profile.bio),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Edit Profile'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  child: const Text('Share Profile'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                child: const Icon(Icons.person_add_outlined, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.person_pin_outlined)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: 10, // Replace with actual user posts
                          itemBuilder: (context, index) {
                            return Image.network(
                              'https://picsum.photos/seed/${index + 1}/200',
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        const Center(child: Text('Tagged Posts Go Here')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
