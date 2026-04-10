import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  /// Get current user ID from Supabase auth
  String? getCurrentUserId() {
    return currentUser?.id;
  }

  /// Get current user from Supabase auth
  User? getCurrentUser() {
    return currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return currentUser != null;
  }

  /// Get user profile data
  /// Returns a Result with user data or error/not found
  Future<Result<Map<String, dynamic>>> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return const Failure(
          NotFoundException(message: 'User profile not found'),
        );
      }

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get user profile: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Update user profile
  /// Returns a Result indicating success or failure
  Future<Result<void>> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('users').update(data).eq('id', userId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to update user profile: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Follow a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> followUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      await supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to follow user: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Unfollow a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> unfollowUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      await supabase.from('follows').delete().match({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to unfollow user: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Search users
  /// Returns a Result with list of users or error
  Future<Result<List<Map<String, dynamic>>>> searchUsers(String query) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .ilike('username', '%$query%')
          .limit(20);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to search users: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get users to follow (suggestions)
  /// Returns a Result with list of suggested users or error
  Future<Result<List<Map<String, dynamic>>>> getSuggestedUsers(
    String currentUserId,
  ) async {
    try {
      // Get users that the current user is not following
      final response = await supabase
          .from('users')
          .select()
          .neq('id', currentUserId)
          .limit(10);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get suggested users: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Create user profile
  /// Returns a Result indicating success or failure
  Future<Result<void>> createUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final dataWithId = {
        ...userData,
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('users').insert(dataWithId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to create user profile: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}
