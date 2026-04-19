import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/features/feed/models/post_model.dart';

final reelsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await PostRepository().getPosts();
  return result.fold(
    (_) => <Post>[],
    (posts) => posts
        .where((p) => (p['video_url'] as String? ?? '').isNotEmpty ||
            (p['imageUrl'] as String? ?? '').isNotEmpty)
        .map((p) => Post(
              id: p['id']?.toString() ?? '',
              username: p['username'] ?? 'unknown',
              userAvatar: p['userAvatar'] ?? '',
              imageUrl: p['imageUrl'] ?? '',
              caption: p['caption'] ?? '',
              likes: (p['likes'] as int?) ?? 0,
              comments: (p['commentsCount'] as int?) ?? 0,
            ))
        .toList(),
  );
});
