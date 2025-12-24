import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/post_model.dart';

final searchProvider = FutureProvider<List<Post>>((ref) async {
  // Simulate a network request
  await Future.delayed(const Duration(seconds: 1));

  return List.generate(
    20,
    (index) => Post(
      id: index.toString(),
      username: 'user$index',
      userAvatar: 'https://picsum.photos/200',
      imageUrl: 'https://picsum.photos/seed/search/$index/200/300',
      caption: 'This is a great post!',
      likes: index * 10,
      comments: index * 2,
    ),
  );
});
