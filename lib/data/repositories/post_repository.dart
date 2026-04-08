import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import 'base_repository.dart';

class PostRepository extends BaseRepository {
  /// Get all posts from Firestore
  /// Returns a Result with list of posts or an error
  Future<Result<List<Map<String, dynamic>>>> getPosts() async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  /// Get a single post by ID
  /// Returns a Result with the post data or error/not found
  Future<Result<Map<String, dynamic>>> getPost(String postId) async {
    return withRetry<Map<String, dynamic>>(() async {
      final DocumentSnapshot doc = await firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!doc.exists) {
        throw NotFoundException(message: 'Post not found');
      }

      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    });
  }

  /// Create a new post
  /// Returns a Result with the created post ID or error
  Future<Result<String>> createPost(Map<String, dynamic> postData) async {
    return withRetry<String>(() async {
      final DocumentReference docRef = await firestore.collection('posts').add({
        ...postData,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'commentsCount': 0,
      });
      return docRef.id;
    });
  }

  /// Like a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> likePost(String postId, String userId) async {
    return withRetry<void>(() async {
      await firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  /// Unlike a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> unlikePost(String postId, String userId) async {
    return withRetry<void>(() async {
      await firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    });
  }

  /// Get posts by user
  /// Returns a Result with list of user posts or error
  Future<Result<List<Map<String, dynamic>>>> getUserPosts(String userId) async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  /// Delete a post
  /// Returns a Result indicating success or failure
  Future<Result<void>> deletePost(String postId) async {
    return withRetry<void>(() async {
      await firestore.collection('posts').doc(postId).delete();
    });
  }

  /// Get posts feed with pagination
  /// [lastDoc] - Optional document to start after for pagination
  /// [limit] - Number of posts to fetch
  Future<Result<List<Map<String, dynamic>>>> getPostsPaginated({
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      Query query = firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }
}
