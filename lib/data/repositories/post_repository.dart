import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';

/// Post repository with real-time support
class PostRepository extends BaseRepository {
  /// Get all posts joined with user profile data
  Future<Result<List<Map<String, dynamic>>>> getPosts({int limit = 30}) async {
    try {
      final response = await supabase
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey(
              id, username, full_name, avatar_url
            ),
            post_likes(count),
            comments(count)
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      // Flatten profile data into post map for easy access
      final posts = (response as List).map<Map<String, dynamic>>((raw) {
        final profile = raw['profiles'] as Map<String, dynamic>? ?? {};
        final likesCount = (raw['post_likes'] as List?)?.isNotEmpty == true
            ? ((raw['post_likes'] as List)[0]['count'] as int?) ?? 0
            : 0;
        final commentsCount = (raw['comments'] as List?)?.isNotEmpty == true
            ? ((raw['comments'] as List)[0]['count'] as int?) ?? 0
            : 0;
        return {
          ...raw,
          'username': profile['username'] ?? 'unknown',
          'userFullName': profile['full_name'] ?? profile['username'] ?? 'User',
          'userAvatar': profile['avatar_url'] ?? '',
          'likes': likesCount,
          'commentsCount': commentsCount,
          'imageUrl': raw['image_url'] ?? raw['imageUrl'] ?? '',
          'location': raw['location'] ?? '',
          'caption': raw['caption'] ?? '',
        };
      }).toList();

      return Success(posts);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get posts: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
  /// Returns a Result with the post data or error/not found
  Future<Result<Map<String, dynamic>>> getPost(String postId) async {
    try {
      final response = await supabase
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey(id, username, full_name, avatar_url),
            post_likes(count),
            comments(count)
          ''')
          .eq('id', postId)
          .maybeSingle();

      if (response == null) {
        return const Failure(NotFoundException(message: 'Post not found'));
      }

      final profile = response['profiles'] as Map<String, dynamic>? ?? {};
      final likesCount = (response['post_likes'] as List?)?.isNotEmpty == true
          ? ((response['post_likes'] as List)[0]['count'] as int?) ?? 0 : 0;
      final commentsCount = (response['comments'] as List?)?.isNotEmpty == true
          ? ((response['comments'] as List)[0]['count'] as int?) ?? 0 : 0;

      final enriched = {
        ...response,
        'username': profile['username'] ?? 'unknown',
        'userAvatar': profile['avatar_url'] ?? '',
        'userFullName': profile['full_name'] ?? '',
        'imageUrl': response['image_url'] ?? '',
        'likes': likesCount,
        'commentsCount': commentsCount,
      };

      return Success(enriched);
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
          .select('*, post_likes(count), comments(count)')
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      final posts = (response as List).map<Map<String, dynamic>>((raw) {
        final likesCount = (raw['post_likes'] as List?)?.isNotEmpty == true
            ? ((raw['post_likes'] as List)[0]['count'] as int?) ?? 0 : 0;
        final commentsCount = (raw['comments'] as List?)?.isNotEmpty == true
            ? ((raw['comments'] as List)[0]['count'] as int?) ?? 0 : 0;
        return {
          ...raw,
          'imageUrl': raw['image_url'] ?? '',
          'likes': likesCount,
          'commentsCount': commentsCount,
        };
      }).toList();

      return Success(posts);
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
      return Failure(DatabaseException(
        message: 'Failed to delete post: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Check if a user has liked a post
  Future<bool> isPostLikedByUser(String postId, String userId) async {
    try {
      final result = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  /// Save a post
  Future<Result<void>> savePost(String postId, String userId) async {
    try {
      await supabase.from('saved_posts').upsert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to save post: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Unsave a post
  Future<Result<void>> unsavePost(String postId, String userId) async {
    try {
      await supabase
          .from('saved_posts')
          .delete()
          .match({'post_id': postId, 'user_id': userId});
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to unsave post: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Get comments for a post
  Future<Result<List<Map<String, dynamic>>>> getComments(String postId) async {
    try {
      final response = await supabase
          .from('comments')
          .select('''
            *,
            profiles!comments_user_id_fkey(username, avatar_url)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final comments = (response as List).map<Map<String, dynamic>>((raw) {
        final profile = raw['profiles'] as Map<String, dynamic>? ?? {};
        return {
          ...raw,
          'username': profile['username'] ?? 'user',
          'avatar': profile['avatar_url'] ?? '',
        };
      }).toList();

      return Success(comments);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to get comments: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Add a comment to a post
  Future<Result<Map<String, dynamic>>> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      final response = await supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'text': text,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            profiles!comments_user_id_fkey(username, avatar_url)
          ''')
          .single();

      final profile =
          (response['profiles'] as Map<String, dynamic>?) ?? {};
      return Success({
        ...response,
        'username': profile['username'] ?? 'you',
        'avatar': profile['avatar_url'] ?? '',
      });
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to add comment: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Get posts with pagination
  Future<Result<List<Map<String, dynamic>>>> getPostsPaginated({
    String? lastDoc,
    int limit = 20,
  }) async {
    try {
      if (lastDoc != null) {
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
          return Success(response as List<Map<String, dynamic>>);
        }
      }
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return Success(response as List<Map<String, dynamic>>);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to get posts: ${e.toString()}',
        originalError: e,
      ));
    }
  }
