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

  /// Get user profile data with follower/following counts
  Future<Result<Map<String, dynamic>>> getUserProfile(String userId) async {
    try {
      // Try UUID lookup first; fall back to username lookup if not a valid UUID
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false).hasMatch(userId);

      dynamic response;
      if (isUuid) {
        response = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
      } else {
        response = await supabase.from('profiles').select().eq('username', userId).maybeSingle();
      }

      if (response == null) {
        return const Failure(NotFoundException(message: 'User profile not found'));
      }

      // Fetch follower & following counts separately
      final followerRows = await supabase
          .from('follows')
          .select()
          .eq('following_id', userId);
      final followingRows = await supabase
          .from('follows')
          .select()
          .eq('follower_id', userId);

      final Map<String, dynamic> enriched = {
        ...response as Map<String, dynamic>,
        'followers_count': (followerRows as List).length,
        'following_count': (followingRows as List).length,
      };

      return Success(enriched);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to get user profile: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Update user profile
  /// Returns a Result indicating success or failure
  Future<Result<void>> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('profiles').update(data).eq('id', userId);

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
          .from('profiles')
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
      // Get IDs of users already followed
      final followed = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);
      final followedIds = (followed as List)
          .map((r) => r['following_id'] as String)
          .toList();

      var query = supabase.from('profiles').select();
      // Exclude self
      query = query.neq('id', currentUserId);
      
      final response = await query.limit(20);
      
      // Filter out already-followed in Dart (Supabase free tier has limited filter ops)
      final filtered = (response as List)
          .where((u) => !followedIds.contains(u['id']))
          .take(10)
          .toList();
      
      final List<Map<String, dynamic>> typedResponse = filtered
          .map((u) => u as Map<String, dynamic>)
          .toList();
      return Success(typedResponse);
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
  /// Get user profile by username (resolves username → UUID)
  Future<Result<Map<String, dynamic>>> getUserByUsername(String username) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();
      if (response == null) return const Failure(NotFoundException(message: 'User not found'));
      return Success(response);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final res = await supabase
          .from('follows')
          .select('follower_id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

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

      await supabase.from('profiles').insert(dataWithId);

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
