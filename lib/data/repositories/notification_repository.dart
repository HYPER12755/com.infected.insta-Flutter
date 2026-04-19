import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  /// Real-time stream of notifications for a user
  Stream<Result<List<Map<String, dynamic>>>> getNotifications(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => Success<List<Map<String, dynamic>>>(rows))
        .handleError((e) => Failure<List<Map<String, dynamic>>>(
            DatabaseException(message: e.toString(), originalError: e)));
  }

  Future<Result<void>> createNotification(Map<String, dynamic> data) async {
    try {
      await supabase.from('notifications').insert({
        ...data,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }

  Future<Result<void>> markAsRead(String id) async {
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }

  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await supabase.from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }

  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final res = await supabase.from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      return Success((res as List).length);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }

  Future<Result<void>> deleteNotification(String id) async {
    try {
      await supabase.from('notifications').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(message: e.toString(), originalError: e));
    }
  }
}
