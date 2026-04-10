import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../supabase/supabase_client.dart';
import '../models/post.dart';

final postRepositoryProvider = Provider((ref) => PostRepository());

class PostRepository {
  /// Create a new post
  Future<void> createPost(Post post) async {
    final data = post.toJson();
    data['id'] = post.id;
    data['created_at'] = DateTime.now().toIso8601String();

    await supabase.from('posts').insert(data);
  }

  /// Get all posts stream for real-time updates
  Stream<List<Post>> getPosts() {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (maps) => maps.map((data) {
            return Post.fromMap(data, data['id'] as String);
          }).toList(),
        );
  }

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    await supabase.from('post_likes').insert({
      'post_id': postId,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    await supabase.from('post_likes').delete().match({
      'post_id': postId,
      'user_id': userId,
    });
  }
}
