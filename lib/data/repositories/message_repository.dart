import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import 'base_repository.dart';

class MessageRepository extends BaseRepository {
  /// Get all conversations for a user
  /// Returns a Result with list of conversations or error
  Future<Result<List<Map<String, dynamic>>>> getConversations(
    String userId,
  ) async {
    return withRetry<List<Map<String, dynamic>>>(() async {
      final QuerySnapshot snapshot = await firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  /// Get messages for a conversation
  /// Returns a Stream of Result with list of messages
  Stream<Result<List<Map<String, dynamic>>>> getMessages(
    String conversationId,
  ) {
    return firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          try {
            final messages = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
            return Success<List<Map<String, dynamic>>>(messages);
          } catch (e) {
            return Failure<List<Map<String, dynamic>>>(
              DatabaseException(
                message: 'Error fetching messages: $e',
                originalError: e,
              ),
            );
          }
        });
  }

  /// Send a message
  /// Returns a Result indicating success or failure
  Future<Result<void>> sendMessage(
    String conversationId,
    Map<String, dynamic> message,
  ) async {
    return withRetry<void>(() async {
      // Add message to messages subcollection
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({...message, 'createdAt': FieldValue.serverTimestamp()});

      // Update conversation last message
      await firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message['text'],
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': message['senderId'],
      });
    });
  }

  /// Create a new conversation
  /// Returns a Result with the created conversation ID or error
  Future<Result<String>> createConversation(List<String> participants) async {
    return withRetry<String>(() async {
      final DocumentReference docRef = await firestore
          .collection('conversations')
          .add({
            'participants': participants,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    });
  }

  /// Get or create conversation between two users
  /// Returns a Result with the conversation ID or error
  Future<Result<String>> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    return withRetry<String>(() async {
      // Check if conversation exists
      final QuerySnapshot snapshot = await firestore
          .collection('conversations')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['participants'] as List).contains(userId2)) {
          return doc.id;
        }
      }

      // Create new conversation
      final newDocRef = await firestore.collection('conversations').add({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      return newDocRef.id;
    });
  }

  /// Mark conversation as read
  /// Returns a Result indicating success or failure
  Future<Result<void>> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    return withRetry<void>(() async {
      await firestore.collection('conversations').doc(conversationId).update({
        'lastReadBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  /// Delete a conversation
  /// Returns a Result indicating success or failure
  Future<Result<void>> deleteConversation(String conversationId) async {
    return withRetry<void>(() async {
      // Delete all messages in the conversation
      final messagesSnapshot = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the conversation
      await firestore.collection('conversations').doc(conversationId).delete();
    });
  }
}
