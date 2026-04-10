import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';
import '../realtime/realtime_notifications_service.dart';

/// Notification repository with real-time support
class NotificationRepository extends BaseRepository {
  // Real-time service for live notifications
  final RealtimeNotificationsService _realtimeService =
      RealtimeNotificationsService();

  /// Get notifications for a user
  /// Returns a Stream of Result with list of notifications
  /// Uses Supabase Realtime stream for real-time updates
  Stream<Result<List<Map<String, dynamic>>>> getNotifications(String userId) {
    // Use real-time service for live notifications
    return _realtimeService.getNotificationsStream(userId)
        .map((maps) => Success<List<Map<String, dynamic>>>(maps))
        .handleError(
          (error) => Failure<List<Map<String, dynamic>>>(
            DatabaseException(
              message: 'Failed to get notifications: ${error.toString()}',
              originalError: error,
            ),
          ),
        );
  }

  /// Watch for new notifications in real-time
  Stream<Result<Map<String, dynamic>>> watchNewNotifications(String userId) {
    return _realtimeService.watchNewNotifications(userId)
        .map((notification) => Success<Map<String, dynamic>>(notification))
        .handleError(
          (error) => Failure<Map<String, dynamic>>(
            DatabaseException(
              message: 'Failed to watch notifications: ${error.toString()}',
              originalError: error,
            ),
          ),
        );
  }

  /// Prepare push notification payload
  RealtimeNotificationPayload preparePushPayload(Map<String, dynamic> notification) {
    return RealtimeNotificationsService.preparePushPayload(notification);
  }

  Future<Result<List<Map<String, dynamic>>>> _fetchNotifications(
    String userId,
  ) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get notifications: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Create a notification
  /// Returns a Result indicating success or failure
  Future<Result<void>> createNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      final dataWithTimestamp = {
        ...notification,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      };

      await supabase.from('notifications').insert(dataWithTimestamp);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to create notification: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Mark notification as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to mark notification as read: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Mark all notifications as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to mark all notifications as read: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get unread notification count
  /// Returns a Result with the count or error
  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return Success(response.length);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get unread count: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Delete a notification
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to delete notification: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Delete all notifications for a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteAllNotifications(String userId) async {
    try {
      await supabase.from('notifications').delete().eq('user_id', userId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to delete all notifications: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}
