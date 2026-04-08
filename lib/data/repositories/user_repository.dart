import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/result.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get user profile data
  /// Returns a Result with user data or error/not found
  Future<Result<Map<String, dynamic>>> getUserProfile(String userId) async {
    return withRetry<Map<String, dynamic>>(() async {
      final DocumentSnapshot doc = await firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw NotFoundException(message: 'User profile not found');
      }

      return doc.data() as Map<String, dynamic>;
    });
  }

  /// Update user profile
  /// Returns a Result indicating success or failure
  Future<Result<void>> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    return withRetry<void>(() async {
      await firestore.collection('users').doc(userId).update(data);
    });
  }

  /// Follow a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> followUser(
    String currentUserId,
    String targetUserId,
  ) async {
    return withRetry<void>(() async {
      // Add to current user's following
      await firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      // Add to target user's followers
      await firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
    });
  }

  /// Unfollow a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> unfollowUser(
    String currentUserId,
    String targetUserId,
  ) async {
    return withRetry<void>(() async {
      // Remove from current user's following
      await firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      // Remove from target user's followers
      await firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  /// Search users
  /// Returns a Result with list of users or error
  Future<Result<List<Map<String, dynamic>>>> searchUsers(String query) async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  /// Get users to follow (suggestions)
  /// Returns a Result with list of suggested users or error
  Future<Result<List<Map<String, dynamic>>>> getSuggestedUsers(
    String currentUserId,
  ) async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('users')
          .limit(10)
          .get();

      return snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  /// Create user profile
  /// Returns a Result indicating success or failure
  Future<Result<void>> createUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    return withRetry<void>(() async {
      await firestore.collection('users').doc(userId).set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
        'posts': 0,
      });
    });
  }
}
