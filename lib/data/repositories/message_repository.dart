import '../../supabase/supabase_client.dart';
import '../models/result.dart';
import 'base_repository.dart';
import '../realtime/realtime_messages_service.dart';

/// Message repository with real-time support
class MessageRepository extends BaseRepository {
  // Real-time service for live updates
  final RealtimeMessagesService _realtimeService = RealtimeMessagesService();
  /// Get all conversations for a user
  /// Returns a Result with list of conversations or error
  Future<Result<List<Map<String, dynamic>>>> getConversations(
    String userId,
  ) async {
    try {
      // Get conversations where the user is a participant
      final response = await supabase
          .from('conversations')
          .select()
          .contains('participant_ids', [userId])
          .order('updated_at', ascending: false);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get conversations: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get real-time stream of messages for a conversation
  /// Uses Supabase Realtime stream for real-time updates
  Stream<Result<List<Map<String, dynamic>>>> getMessages(
    String conversationId,
  ) {
    // Use the real-time service for messages stream
    return _realtimeService.getMessagesStream(conversationId)
        .map((maps) => Success<List<Map<String, dynamic>>>(maps))
        .handleError(
          (error) => Failure<List<Map<String, dynamic>>>(
            DatabaseException(
              message: 'Failed to get messages: ${error.toString()}',
              originalError: error,
            ),
          ),
        );
  }

  /// Watch for new messages in real-time
  Stream<Result<Map<String, dynamic>>> watchNewMessages(
    String conversationId,
  ) {
    return _realtimeService.watchNewMessages(conversationId)
        .map((message) => Success<Map<String, dynamic>>(message))
        .handleError(
          (error) => Failure<Map<String, dynamic>>(
            DatabaseException(
              message: 'Failed to watch messages: ${error.toString()}',
              originalError: error,
            ),
          ),
        );
  }

  /// Initialize real-time service for a user
  void initializeRealtime(String userId) {
    _realtimeService.initialize(userId);
  }

  /// Start typing indicator
  Future<void> startTyping(String conversationId, String userId) async {
    await _realtimeService.startTyping(conversationId, userId);
  }

  /// Stop typing indicator
  Future<void> stopTyping(String conversationId, String userId) async {
    await _realtimeService.stopTyping(conversationId, userId);
  }

  /// Mark message as delivered
  Future<void> markMessageDelivered(String messageId) async {
    await _realtimeService.markDelivered(messageId);
  }

  /// Mark message as read
  Future<void> markMessageRead(String messageId) async {
    await _realtimeService.markRead(messageId);
  }

  Future<Result<List<Map<String, dynamic>>>> _fetchMessages(
    String conversationId,
  ) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return Success(response);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get messages: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Send a message
  /// Returns a Result indicating success or failure
  Future<Result<void>> sendMessage(
    String conversationId,
    Map<String, dynamic> message,
  ) async {
    try {
      final dataWithTimestamp = {
        ...message,
        'conversation_id': conversationId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('messages').insert(dataWithTimestamp);

      // Update conversation's updated_at timestamp
      await supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to send message: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Create a new conversation
  /// Returns a Result with the created conversation ID or error
  Future<Result<String>> createConversation(List<String> participants) async {
    try {
      final response = await supabase
          .from('conversations')
          .insert({
            'participant_ids': participants,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Success(response['id'] as String);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to create conversation: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Get or create conversation between two users
  /// Returns a Result with the conversation ID or error
  Future<Result<String>> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // First, check if a conversation already exists between these users
      final existing = await supabase.from('conversations').select().contains(
        'participant_ids',
        [userId1, userId2],
      ).maybeSingle();

      if (existing != null) {
        return Success(existing['id'] as String);
      }

      // Create a new conversation
      return createConversation([userId1, userId2]);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to get or create conversation: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Mark conversation as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      // Update messages in the conversation as read
      await supabase
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to mark conversation as read: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }

  /// Delete a conversation
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation first
      await supabase
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Then delete the conversation
      await supabase.from('conversations').delete().eq('id', conversationId);

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseException(
          message: 'Failed to delete conversation: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}
