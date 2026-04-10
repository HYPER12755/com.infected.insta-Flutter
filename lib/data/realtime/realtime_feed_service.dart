import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';

/// Service for real-time feed updates using Supabase Realtime
///
/// Features:
/// - Real-time post streaming from followed users
/// - Live like/comment count updates
/// - New post notifications
class RealtimeFeedService {
  final SupabaseClient _supabase;

  RealtimeChannel? _feedChannel;

  RealtimeFeedService() : _supabase = supabase;

  /// Get all posts stream for feed
  Stream<List<Map<String, dynamic>>> getFeedStream({int limit = 20}) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit);
  }

  /// Watch for new posts (most recent)
  Stream<Map<String, dynamic>> watchNewPosts() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .map((posts) => posts.isNotEmpty ? posts.first : {});
  }

  /// Watch post likes count
  Stream<int> watchPostLikesCount(String postId) {
    return _supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((likes) => likes.length);
  }

  /// Watch post comments count
  Stream<int> watchPostCommentsCount(String postId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((comments) => comments.length);
  }

  /// Watch for new likes on a specific post
  Stream<Map<String, dynamic>> watchNewLikes(String postId) {
    return _supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((likes) => likes.isNotEmpty ? likes.first : {});
  }

  /// Watch for new comments on a specific post
  Stream<Map<String, dynamic>> watchNewComments(String postId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((comments) => comments.isNotEmpty ? comments.first : {});
  }

  /// Subscribe to all posts for feed updates
  Stream<List<Map<String, dynamic>>> subscribeToFeedUpdates() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Create custom channel for feed
  RealtimeChannel createFeedChannel(String channelName) {
    return _supabase.channel(channelName);
  }

  /// Get posts by specific users (for followed users feed)
  /// Note: This fetches all posts and filters in memory for followed users
  Stream<List<Map<String, dynamic>>> getPostsFromUsers(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    // Get all posts and filter client-side for performance
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) =>
              posts.where((post) => userIds.contains(post['user_id'])).toList(),
        );
  }

  /// Clean up
  void dispose() {
    _feedChannel?.unsubscribe();
    _feedChannel = null;
  }
}
