import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';
import '../realtime/realtime_feed_service.dart';

/// Post repository with real-time support
class PostRepository extends BaseRepository {
  // Real-time service for live feed updates
  final RealtimeFeedService _realtimeService = RealtimeFeedService();
  /// Get all posts
  /// Returns a Result with list of posts or an error
  Future<Result<List<Map<String, dynamic>>>> getPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get posts: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get real-time feed stream
  Stream<List<Map<String, dynamic>>> getFeedStream({int limit = 20}) {
    return _realtimeService.getFeedStream(limit: limit);
  }

  /// Watch for new posts in real-time
  Stream<Map<String, dynamic>> watchNewPosts() {
    return _realtimeService.watchNewPosts();
  }

  /// Watch post likes count in real-time
  Stream<int> watchPostLikesCount(String postId) {
    return _realtimeService.watchPostLikesCount(postId);
  }

  /// Watch post comments count in real-time
  Stream<int> watchPostCommentsCount(String postId) {
    return _realtimeService.watchPostCommentsCount(postId);
  }

  /// Watch for new likes on a post
  Stream<Map<String, dynamic>> watchNewLikes(String postId) {
    return _realtimeService.watchNewLikes(postId);
  }

  /// Watch for new comments on a post
  Stream<Map<String, dynamic>> watchNewComments(String postId) {
    return _realtimeService.watchNewComments(postId);
  }

  /// Get posts from followed users in real-time
  Stream<List<Map<String, dynamic>>> getPostsFromUsers(List<String> userIds) {
    return _realtimeService.getPostsFromUsers(userIds);
  }

  /// Get a single post by ID
  /// Returns a Result with the post data or error/not found
  Future<Result<Map<String, dynamic>>> getPost(String postId) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (response == null) {
        return const Failure(NotFoundException(message: 'Post not found'));
      }

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get post: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Create a new post
  /// Returns a Result with the created post ID or error
  Future<Result<String>> createPost(Map<String, dynamic> postData) async {
    try {
      final dataWithTimestamp = {
        ...postData,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('posts')
          .insert(dataWithTimestamp)
          .select()
          .single();

      return Success(response['id'] as String);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to create post: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Like a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> likePost(String postId, String userId) async {
    try {
      await supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to like post: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Unlike a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> unlikePost(String postId, String userId) async {
    try {
      await supabase.from('post_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to unlike post: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get posts by user
  /// Returns a Result with list of user posts or error
  Future<Result<List<Map<String, dynamic>>>> getUserPosts(String userId) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get user posts: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Delete a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to delete post: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get posts feed with pagination
  /// [lastDoc] - Optional document to start after for pagination
  /// [limit] - Number of posts to fetch
  Future<Result<List<Map<String, dynamic>>>> getPostsPaginated({
    String? lastDoc,
    int limit = 20,
  }) async {
    try {
      if (lastDoc != null) {
        // Get the timestamp of the last post to use for pagination
        final lastPost = await supabase
            .from('posts')
            .select('created_at')
            .eq('id', lastDoc)
            .maybeSingle();

        if (lastPost != null) {
          final response = await supabase
              .from('posts')
              .select()
              .lt('created_at', lastPost['created_at'])
              .order('created_at', ascending: false)
              .limit(limit);
          return Success(response);
        }
      }

      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get posts: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}
