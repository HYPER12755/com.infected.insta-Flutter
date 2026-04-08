import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';

import '../../feed/models/post_model.dart';

final reelsProvider = FutureProvider<List<Post>>((ref) async {
  final postRepo = PostRepository();
  final result = await postRepo.getPosts();

  return result.fold(
    (error) => [],
    (posts) => posts
        .map(
          (post) => Post(
            id: post['id'] ?? '',
            username: post['username'] ?? 'Unknown',
            userAvatar: post['profilePicture'] ?? '',
            imageUrl: post['imageUrl'] ?? '',
            caption: post['caption'] ?? '',
            likes: post['likes'] ?? 0,
            comments: post['commentsCount'] ?? 0,
          ),
        )
        .toList(),
  );
});
