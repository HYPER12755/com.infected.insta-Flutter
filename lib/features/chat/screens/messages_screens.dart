import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/data/repositories/message_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';

/// Messages Inbox Screen
class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messageRepo = MessageRepository();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';

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
                MaterialPageRoute(
                  builder: (context) => const NewMessageScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: messageRepo.getConversations(currentUserId).then((result) {
          return result.fold(
            (error) => <Map<String, dynamic>>[],
            (conversations) => conversations,
          );
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading conversations',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _buildConversationTile(context, conv);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Map<String, dynamic> conv,
  ) {
    // Handle both Firestore data and mock data formats
    final String username =
        conv['username'] ?? conv['otherUsername'] ?? 'Unknown';
    final String message = conv['message'] ?? conv['lastMessage'] ?? '';
    final String time =
        conv['time'] ?? _formatTimestamp(conv['lastMessageTime']);
    final bool unread = conv['unread'] ?? false;
    final String avatarLetter = username.isNotEmpty
        ? username[0].toUpperCase()
        : '?';

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationChatScreen(
              conversationId: conv['id'].toString(),
              username: username,
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
              avatarLetter,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (unread)
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
              username,
              style: TextStyle(
                color: InstagramColors.darkText,
                fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: unread
                  ? InstagramColors.primary
                  : InstagramColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: unread
                    ? InstagramColors.darkText
                    : InstagramColors.darkTextSecondary,
                fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unread)
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is String) return timestamp;
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final diff = now.difference(timestamp.toDate());
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    }
    return '';
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
  final MessageRepository _messageRepo = MessageRepository();
  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? 'test_user';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is String) return timestamp;
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '';
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
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    calleeId: widget.conversationId,
                    calleeName: widget.username,
                    callType: CallType.audio,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    calleeId: widget.conversationId,
                    calleeName: widget.username,
                    callType: CallType.video,
                  ),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageRepo
                  .getMessages(widget.conversationId)
                  .map(
                    (result) => result.fold(
                      (error) => <Map<String, dynamic>>[],
                      (messages) => messages,
                    ),
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
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
        mainAxisAlignment: msg['isMe']
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: msg['isMe']
                  ? InstagramColors.primary
                  : InstagramColors.darkSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg['text'],
                  style: TextStyle(
                    color: msg['isMe']
                        ? Colors.white
                        : InstagramColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg['time'],
                      style: TextStyle(
                        color: msg['isMe']
                            ? Colors.white70
                            : InstagramColors.darkTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (msg['isMe']) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 14,
                        color: Colors.white70,
                      ),
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
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: InstagramColors.darkText,
              ),
              onPressed: () {},
            ),
            // Gallery button
            IconButton(
              icon: const Icon(
                Icons.photo_library_outlined,
                color: InstagramColors.darkText,
              ),
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
                          hintStyle: TextStyle(
                            color: InstagramColors.darkTextSecondary,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: InstagramColors.darkText),
                      ),
                    ),
                    // Emoji button
                    const Icon(
                      Icons.emoji_emotions_outlined,
                      color: InstagramColors.darkTextSecondary,
                    ),
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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final messageText = _messageController.text.trim();

    // Send message via repository
    await _messageRepo.sendMessage(widget.conversationId, {
      'text': messageText,
      'senderId': _currentUserId,
      'isRead': false,
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
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final userRepo = UserRepository();
      final currentUserId = userRepo.getCurrentUserId();

      if (currentUserId != null) {
        final result = await userRepo.getSuggestedUsers(currentUserId);
        result.fold(
          (error) {
            if (mounted) setState(() => _isLoading = false);
          },
          (users) {
            if (mounted) {
              setState(() {
                _users = users;
                _isLoading = false;
              });
            }
          },
        );
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users
        .where(
          (user) => (user['username'] ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
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
                prefixIcon: const Icon(
                  Icons.search,
                  color: InstagramColors.darkTextSecondary,
                ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: InstagramColors.darkText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No results for "$_searchQuery"',
                              style: TextStyle(
                                color: InstagramColors.darkText.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final avatarUrl = user['profilePicture'] as String?;
                          final username = user['username'] ?? user['displayName'] ?? 'User';
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: InstagramColors.primary,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                color: InstagramColors.darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.message_outlined,
                              color: InstagramColors.primary,
                            ),
                            onTap: () {
                              // Start conversation
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConversationChatScreen(
                                    conversationId: user['id'].toString(),
                                    username: username,
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
            const Icon(
              Icons.send_outlined,
              size: 60,
              color: InstagramColors.darkTextSecondary,
            ),
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
class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch message requests from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('message_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _requests = snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text('Message Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: InstagramColors.darkText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No message requests',
                        style: TextStyle(
                          color: InstagramColors.darkText.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: InstagramColors.primary,
                        child: Text(
                          req['username']?.toString().isNotEmpty == true
                              ? req['username'].toString()[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        req['username']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          color: InstagramColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        req['message']?.toString() ?? '',
                        style: const TextStyle(color: InstagramColors.darkTextSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              // Accept request
                              await FirebaseFirestore.instance
                                  .collection('message_requests')
                                  .doc(req['id'])
                                  .update({'status': 'accepted'});
                              _loadRequests();
                            },
                            child: const Text(
                              'Accept',
                              style: TextStyle(color: InstagramColors.primary),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Decline request
                              await FirebaseFirestore.instance
                                  .collection('message_requests')
                                  .doc(req['id'])
                                  .update({'status': 'declined'});
                              _loadRequests();
                            },
                            child: const Text(
                              'Decline',
                              style: TextStyle(color: InstagramColors.darkTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
