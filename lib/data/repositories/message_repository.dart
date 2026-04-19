import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';

class MessageRepository extends BaseRepository {
  // ── Conversations ────────────────────────────────────────────────────────
  Future<Result<List<Map<String, dynamic>>>> getConversations(String userId) async {
    try {
      // Fetch conversations where user is a participant
      final res = await supabase
          .from('conversations')
          .select('id, updated_at, last_message, last_sender_id, participant_ids')
          .contains('participant_ids', [userId])
          .order('updated_at', ascending: false);

      final convList = res as List;
      final convs = <Map<String, dynamic>>[];

      for (final conv in convList) {
        final ids = (conv['participant_ids'] as List).cast<String>();
        final otherId = ids.firstWhere((id) => id != userId, orElse: () => '');

        Map<String, dynamic> profile = {};
        if (otherId.isNotEmpty) {
          try {
            final p = await supabase
                .from('profiles')
                .select('id, username, avatar_url, full_name')
                .eq('id', otherId)
                .maybeSingle();
            if (p != null) profile = p as Map<String, dynamic>;
          } catch (_) {}
        }

        convs.add({
          'id': conv['id'],
          'updated_at': conv['updated_at'],
          'last_message': conv['last_message'] ?? '',
          'last_sender_id': conv['last_sender_id'],
          'otherUserId': profile['id'] ?? otherId,
          'username': profile['username'] ?? 'User',
          'avatar': profile['avatar_url'] ?? '',
          'name': profile['full_name'] ?? profile['username'] ?? 'User',
        });
      }

      return Success(convs);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to get conversations: $e', originalError: e));
    }
  }

  /// Get or create a 1:1 conversation between two users
  Future<Result<String>> getOrCreateConversation(String userId1, String userId2) async {
    try {
      // Try to find existing
      final existing = await supabase
          .from('conversations')
          .select('id')
          .contains('participant_ids', [userId1])
          .contains('participant_ids', [userId2])
          .maybeSingle();

      if (existing != null) return Success(existing['id'] as String);

      // Create new
      final created = await supabase.from('conversations').insert({
        'participant_ids': [userId1, userId2],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_message': '',
      }).select('id').single();

      return Success(created['id'] as String);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to get/create conversation: $e', originalError: e));
    }
  }

  // ── Messages stream (real-time) ──────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getMessagesStream(
      String conversationId, String currentUserId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map<Map<String, dynamic>>((r) => {
              ...r,
              'isMe': r['sender_id'] == currentUserId,
              'text': r['text'] ?? r['content'] ?? '',
              'reply_text': r['reply_text'],
              'reply_sender': r['reply_sender'],
              'is_deleted': r['is_deleted'] ?? false,
              'reactions': r['reactions'] ?? [],
            }).toList());
  }

  /// Compatibility wrapper that returns a Stream<Result<...>>
  Stream<Result<List<Map<String, dynamic>>>> getMessages(String conversationId) {
    final uid = currentUser?.id ?? '';
    return getMessagesStream(conversationId, uid)
        .map((msgs) => Success<List<Map<String, dynamic>>>(msgs));
  }

  // ── Send message ─────────────────────────────────────────────────────────
  Future<Result<void>> sendMessage(
      String conversationId, Map<String, dynamic> data) async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return const Failure(DatabaseException(message: 'Not authenticated'));

      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': uid,
        'text': data['text'] ?? data['content'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        // Optional reply fields
        if (data['reply_to_id'] != null) 'reply_to_id': data['reply_to_id'],
        if (data['reply_text'] != null)  'reply_text': data['reply_text'],
        if (data['reply_sender'] != null)'reply_sender': data['reply_sender'],
      });

      // Update conversation preview
      await supabase.from('conversations').update({
        'last_message': data['text'] ?? data['content'] ?? '',
        'last_sender_id': uid,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to send message: $e', originalError: e));
    }
  }

  // ── Mark messages as read ────────────────────────────────────────────────
  Future<void> markConversationRead(String conversationId, String userId) async {
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  // ── Typing indicator (broadcast) ─────────────────────────────────────────
  RealtimeChannel typingChannel(String conversationId) {
    return supabase.channel('typing:$conversationId');
  }

  Future<void> sendTyping(String conversationId, String userId, bool isTyping) async {
    try {
      await supabase.from('typing_indicators').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Stream<bool> watchTyping(String conversationId, String otherUserId) {
    return supabase
        .from('typing_indicators')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .map((rows) {
          final row = rows.where((r) => r['user_id'] == otherUserId).firstOrNull;
          if (row == null) return false;
          final updated = DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime(2000);
          return row['is_typing'] == true &&
              DateTime.now().difference(updated).inSeconds < 4;
        });
  }

  // ── Unread count ─────────────────────────────────────────────────────────
  Stream<int> getUnreadCount(String userId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((r) => r['is_read'] != true && r['sender_id'] != userId)
            .length);
  }

  // ── Legacy compat ────────────────────────────────────────────────────────
  Future<void> startTyping(String conversationId, String userId) =>
      sendTyping(conversationId, userId, true);
  Future<void> stopTyping(String conversationId, String userId) =>
      sendTyping(conversationId, userId, false);
  void initializeRealtime(String userId) {}

  Future<Result<String>> createConversation(List<String> participants) async {
    try {
      final res = await supabase.from('conversations').insert({
        'participant_ids': participants,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_message': '',
      }).select('id').single();
      return Success(res['id'] as String);
    } catch (e) {
      return Failure(DatabaseException(
        message: 'Failed to create conversation: $e', originalError: e));
    }
  }
}
