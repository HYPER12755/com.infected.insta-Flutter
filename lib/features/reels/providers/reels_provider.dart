import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/post_model.dart';

final reelsProvider = FutureProvider<List<Post>>((ref) async {
  // Simulate a network request
  await Future.delayed(const Duration(seconds: 1));

  return List.generate(
    10,
    (index) => Post(
      id: index.toString(),
      username: 'user$index',
      userAvatar: 'https://picsum.photos/200',
      imageUrl: 'https://picsum.photos/seed/reels/$index/400/800',
      caption: 'This is a cool reel!',
      likes: index * 20,
      comments: index * 5,
    ),
  );
});
