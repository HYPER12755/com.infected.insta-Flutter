import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              // Navigate to new chat - TODO: implement
            },
          ),
        ],
      ),
      body: const _ChatList(),
    );
  }
}

class _ChatList extends StatefulWidget {
  const _ChatList();

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> {
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<QueryDocumentSnapshot> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch conversations from Firestore
      final conversationsRef = FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTime', descending: true);

      final snapshot = await conversationsRef.get();

      setState(() {
        _conversations = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by following someone',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final data = conversation.data() as Map<String, dynamic>;

          // Get other participant
          final participants = data['participants'] as List<dynamic>? ?? [];
          final otherUserId = participants.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get(),
            builder: (context, userSnapshot) {
              String userName = 'Unknown';
              String? userAvatar;

              if (userSnapshot.hasData) {
                final userDoc = userSnapshot.data;
                if (userDoc != null) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  if (userData != null) {
                    userName = userData['displayName'] ?? userData['username'] ?? 'Unknown';
                    userAvatar = userData['photoURL'];
                  }
                }
              }

              final unreadCount = data['unreadCount'] as int?;

              return _ConversationTile(
                conversationId: conversation.id,
                otherUserId: otherUserId,
                otherUserName: userName,
                otherUserAvatar: userAvatar,
                lastMessage: data['lastMessage'] as String? ?? '',
                lastMessageTime:
                    (data['lastMessageTime'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0,
                isUnread: unreadCount != null && unreadCount > 0,
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final int lastMessageTime;
  final bool isUnread;

  const _ConversationTile({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
  });

  String _formatTime(int timestamp) {
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageTime.weekday - 1];
    } else {
      return '${messageTime.month}/${messageTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).primaryColor.withAlpha(77),
        backgroundImage: otherUserAvatar != null
            ? NetworkImage(otherUserAvatar!)
            : null,
        child: otherUserAvatar == null
            ? Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : null,
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: isUnread ? Colors.white : Colors.grey,
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(lastMessageTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          if (isUnread)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFC039FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to actual chat conversation
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ChatConversationScreen(
        //       conversationId: conversationId,
        //       otherUserId: otherUserId,
        //       otherUserName: otherUserName,
        //       otherUserAvatar: otherUserAvatar,
        //     ),
        //   ),
        // );
      },
    );
  }
}
