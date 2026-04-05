import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Messages Inbox Screen
class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock conversations
    final conversations = List.generate(15, (index) {
      return {
        'id': index,
        'username': 'user_${index + 1}',
        'message': index % 2 == 0 ? 'Hey! How are you?' : 'Check out this post! 🔥',
        'time': '${index + 1}h',
        'unread': index < 3,
        'avatar': String.fromCharCode(65 + index),
      };
    });

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewMessageScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          return _buildConversationTile(context, conv);
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> conv) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationChatScreen(
              conversationId: conv['id'].toString(),
              username: conv['username'],
            ),
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: InstagramColors.primary,
            child: Text(
              conv['avatar'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (conv['unread'])
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.circle, size: 14, color: Colors.green),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conv['username'],
              style: TextStyle(
                color: InstagramColors.darkText,
                fontWeight: conv['unread'] ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            conv['time'],
            style: TextStyle(
              color: conv['unread'] ? InstagramColors.primary : InstagramColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conv['message'],
              style: TextStyle(
                color: conv['unread'] ? InstagramColors.darkText : InstagramColors.darkTextSecondary,
                fontWeight: conv['unread'] ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conv['unread'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: InstagramColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'New',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Conversation Chat Screen
class ConversationChatScreen extends StatefulWidget {
  final String conversationId;
  final String username;
  final String? userAvatar;
  
  const ConversationChatScreen({
    super.key,
    required this.conversationId,
    required this.username,
    this.userAvatar,
  });

  @override
  State<ConversationChatScreen> createState() => _ConversationChatScreenState();
}

class _ConversationChatScreenState extends State<ConversationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  
  final List<Map<String, dynamic>> _messages = List.generate(20, (index) {
    return {
      'id': index,
      'text': index % 2 == 0 
          ? 'Hey there! How\'s it going?' 
          : 'Doing great! Thanks for asking 😊',
      'isMe': index % 2 == 0,
      'time': '${index + 1}:${(index * 7).toString().padLeft(2, '0')}',
    };
  });

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: InstagramColors.primary,
              child: Text(
                widget.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: msg['isMe'] ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: msg['isMe'] ? InstagramColors.primary : InstagramColors.darkSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg['text'],
                  style: TextStyle(
                    color: msg['isMe'] ? Colors.white : InstagramColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg['time'],
                      style: TextStyle(
                        color: msg['isMe'] ? Colors.white70 : InstagramColors.darkTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (msg['isMe']) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        border: Border(top: BorderSide(color: InstagramColors.darkSecondary)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera button
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: InstagramColors.darkText),
              onPressed: () {},
            ),
            // Gallery button
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: InstagramColors.darkText),
              onPressed: () {},
            ),
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: InstagramColors.darkSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: InstagramColors.darkTextSecondary),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: InstagramColors.darkText),
                      ),
                    ),
                    // Emoji button
                    const Icon(Icons.emoji_emotions_outlined, color: InstagramColors.darkTextSecondary),
                  ],
                ),
              ),
            ),
            // Send button
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: InstagramColors.primary),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    
    // Add message to list
    setState(() {
      _messages.add({
        'id': _messages.length,
        'text': _messageController.text,
        'isMe': true,
        'time': 'Now',
      });
    });
    
    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isSending = false);
    });
  }
}

/// New Message Screen
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allUsers = List.generate(30, (index) {
    return {
      'id': index,
      'username': 'user_${index + 1}',
      'avatar': String.fromCharCode(65 + (index % 26)),
    };
  });

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((user) => 
      user['username'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search, color: InstagramColors.darkTextSecondary),
                filled: true,
                fillColor: InstagramColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Suggested or recent
          if (_searchQuery.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: InstagramColors.darkText,
                  ),
                ),
              ),
            ),
          // User list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: InstagramColors.primary,
                    child: Text(user['avatar'], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    user['username'],
                    style: const TextStyle(color: InstagramColors.darkText, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.message_outlined, color: InstagramColors.primary),
                  onTap: () {
                    // Start conversation
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationChatScreen(
                          conversationId: user['id'].toString(),
                          username: user['username'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Story Share Screen
class StoryShareScreen extends StatelessWidget {
  const StoryShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Share'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_outlined, size: 60, color: InstagramColors.darkTextSecondary),
            const SizedBox(height: 16),
            const Text(
              'Share to your story',
              style: TextStyle(color: InstagramColors.darkText, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'This post will be visible on your profile for 24 hours.',
              style: TextStyle(color: InstagramColors.darkTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Share to Story'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message Requests Screen
class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock requests
    final requests = List.generate(5, (index) {
      return {
        'id': index,
        'username': 'user_req_${index + 1}',
        'message': 'Hey! I wanted to connect with you.',
        'time': '${index + 1}d',
      };
    });

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text('Message Requests'),
      ),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: InstagramColors.primary,
              child: Text(req['username']?.toString().isNotEmpty == true ? req['username'].toString()[8].toUpperCase() : '?'),
            ),
            title: Text(
              req['username']?.toString() ?? '',
              style: const TextStyle(color: InstagramColors.darkText, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              req['message']?.toString() ?? '',
              style: const TextStyle(color: InstagramColors.darkTextSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Accept', style: TextStyle(color: InstagramColors.primary)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Decline', style: TextStyle(color: InstagramColors.darkTextSecondary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}