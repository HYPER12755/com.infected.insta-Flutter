import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';

final feedProvider = FutureProvider<List<Post>>((ref) async {
  // Simulate a network request
  await Future.delayed(const Duration(seconds: 2));

  return [
    Post(
      id: '1',
      username: 'user1',
      userAvatar: 'https://picsum.photos/200',
      imageUrl: 'https://picsum.photos/seed/1/200/300',
      caption: 'This is a great post!',
      likes: 123,
      comments: 45,
    ),
    Post(
      id: '2',
      username: 'user2',
      userAvatar: 'https://picsum.photos/200',
      imageUrl: 'https://picsum.photos/seed/2/200/300',
      caption: 'Check out this cool photo!',
      likes: 456,
      comments: 78,
    ),
    Post(
      id: '3',
      username: 'user3',
      userAvatar: 'https://picsum.photos/200',
      imageUrl: 'https://picsum.photos/seed/3/200/300',
      caption: 'Having a great time!',
      likes: 789,
      comments: 12,
    ),
  ];
});
