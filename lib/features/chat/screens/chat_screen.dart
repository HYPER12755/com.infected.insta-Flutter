import 'package:flutter/material.dart';
import 'package:infected_insta/data/repositories/message_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/features/chat/screens/messages_screens.dart' as messages;

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
              // Navigate to new chat - TODO: implement with Supabase
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
  final _messageRepo = MessageRepository();
  final _userRepo = UserRepository();
  late final String? _currentUserId;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentUserId = _userRepo.getCurrentUserId();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final messageRepo = MessageRepository();
      final result = await messageRepo.getConversations(_currentUserId!);
      
      result.fold(
        (error) {
          if (mounted) {
            setState(() {
              _error = error.message;
              _conversations = [];
              _isLoading = false;
            });
          }
        },
        (conversations) {
          if (mounted) {
            setState(() {
              _conversations = conversations.cast<Map<String, dynamic>>();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _conversations = [];
          _isLoading = false;
        });
      }
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
          return _ConversationTile(
            conversationId: conversation['id']?.toString() ?? '',
            otherUserId: conversation['otherUserId']?.toString() ?? '',
            otherUserName:
                conversation['otherUserName']?.toString() ?? 'Unknown',
            otherUserAvatar: conversation['otherUserAvatar']?.toString(),
            lastMessage: conversation['lastMessage']?.toString() ?? '',
            lastMessageTime: conversation['lastMessageTime'] as int? ?? 0,
            isUnread: conversation['isUnread'] as bool? ?? false,
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
    if (timestamp == 0) return '';
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
        // Navigate to conversation chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => messages.ConversationChatScreen(
              conversationId: conversationId,
              username: otherUserName,
              userAvatar: otherUserAvatar,
            ),
          ),
        );
      },
    );
  }
}
