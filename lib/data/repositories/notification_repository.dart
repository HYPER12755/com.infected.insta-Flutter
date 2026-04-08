import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  /// Get notifications for a user
  /// Returns a Stream of Result with list of notifications
  Stream<Result<List<Map<String, dynamic>>>> getNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
            return Success<List<Map<String, dynamic>>>(notifications);
          } catch (e) {
            return Failure<List<Map<String, dynamic>>>(
              DatabaseException(
                message: 'Error fetching notifications: $e',
                originalError: e,
              ),
            );
          }
        });
  }

  /// Create a notification
  /// Returns a Result indicating success or failure
  Future<Result<void>> createNotification(
    Map<String, dynamic> notification,
  ) async {
    return withRetry<void>(() async {
      await firestore.collection('notifications').add({
        ...notification,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    });
  }

  /// Mark notification as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markAsRead(String notificationId) async {
    return withRetry<void>(() async {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    });
  }

  /// Mark all notifications as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markAllAsRead(String userId) async {
    return withRetry<void>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    });
  }

  /// Get unread notification count
  /// Returns a Result with the count or error
  Future<Result<int>> getUnreadCount(String userId) async {
    return withRetry<int>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    });
  }

  /// Delete a notification
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteNotification(String notificationId) async {
    return withRetry<void>(() async {
      await firestore.collection('notifications').doc(notificationId).delete();
    });
  }

  /// Delete all notifications for a user
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteAllNotifications(String userId) async {
    return withRetry<void>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    });
  }
}
