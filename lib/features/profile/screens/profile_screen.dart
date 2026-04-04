import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/profile_provider.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';
import 'package:infected_insta/features/call/models/call_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.when(
          data: (user) => user.username,
          loading: () => 'Profile',
          error: (error, stackTrace) => 'Profile',
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (user) {
          return DefaultTabController(
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
                                backgroundImage: CachedNetworkImageProvider(user.avatarUrl),
                              ),
                              Row(
                                children: [
                                  _buildStatColumn('Posts', user.posts.toString()),
                                  const SizedBox(width: 24),
                                  _buildStatColumn('Followers', user.followers.toString()),
                                  const SizedBox(width: 24),
                                  _buildStatColumn('Following', user.following.toString()),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(user.bio, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Follow', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Message', style: TextStyle(color: Colors.black)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Call buttons added for demo purposes
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // For demo: call self (would be different user in real app)
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => CallScreen(
                                              calleeId: user.userId,
                                              calleeName: user.name,
                                              calleeAvatar: user.avatarUrl,
                                              callType: CallType.audio,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.call, color: Colors.black),
                                      tooltip: 'Audio call',
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        // For demo: video call self (would be different user in real app)
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => CallScreen(
                                              calleeId: user.userId,
                                              calleeName: user.name,
                                              calleeAvatar: user.avatarUrl,
                                              callType: CallType.video,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.videocam, color: Colors.black),
                                      tooltip: 'Video call',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _TabBarDelegate(),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: user.posts,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: 'https://picsum.photos/seed/${user.username}/$index/200/200',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                        ),
                      );
                    },
                  ),
                  const Center(child: Text('Tagged Posts')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined)),
          Tab(icon: Icon(Icons.person_pin_outlined)),
        ],
        indicatorColor: Colors.black,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
