import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';

/// Notification types for real-time events
enum NotificationType {
  like,
  comment,
  follow,
  mention,
  message,
}

/// Payload for push notifications
class RealtimeNotificationPayload {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? senderId;
  final String? postId;
  final String? conversationId;
  final Map<String, dynamic>? data;

  const RealtimeNotificationPayload({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.senderId,
    this.postId,
    this.conversationId,
    this.data,
  });

  /// Convert to push notification payload
  Map<String, dynamic> toPushPayload() {
    return {
      'notification': {
        'id': id,
        'title': title,
        'body': body,
      },
      'data': {
        'type': type,
        'sender_id': senderId,
        'post_id': postId,
        'conversation_id': conversationId,
      },
    };
  }
}

/// Service for real-time notifications using Supabase Realtime
/// 
/// Features:
/// - Real-time notifications stream
/// - Like/comment/follow notifications
/// - Push notification payload preparation
class RealtimeNotificationsService {
  final SupabaseClient _supabase;
  
  RealtimeNotificationsService() : _supabase = supabase;

  /// Get notifications stream for a user
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Watch for new notifications only
  Stream<Map<String, dynamic>> watchNewNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((notifications) => 
            notifications.isNotEmpty ? notifications.first : {});
  }

  /// Create notification channel
  RealtimeChannel createChannel(String userId) {
    return _supabase.channel('notifications:$userId');
  }

  /// Prepare push payload from notification data
  static RealtimeNotificationPayload preparePushPayload(
    Map<String, dynamic> notification,
  ) {
    final type = notification['type'] as String? ?? 'notification';
    final senderId = notification['sender_id'] as String?;
    final senderUsername = notification['sender_username'] as String?;
    final postId = notification['post_id'] as String?;
    final conversationId = notification['conversation_id'] as String?;

    String title;
    String body;

    switch (type) {
      case 'like':
        title = 'New Like';
        body = '$senderUsername liked your post';
        break;
      case 'comment':
        title = 'New Comment';
        body = '$senderUsername commented on your post';
        break;
      case 'follow':
        title = 'New Follower';
        body = '$senderUsername started following you';
        break;
      default:
        title = 'Notification';
        body = notification['content'] as String? ?? 'You have a new notification';
    }

    return RealtimeNotificationPayload(
      id: notification['id'] as String,
      type: type,
      title: title,
      body: body,
      senderId: senderId,
      postId: postId,
      conversationId: conversationId,
      data: notification,
    );
  }
}
