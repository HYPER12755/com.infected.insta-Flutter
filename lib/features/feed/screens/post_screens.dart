import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Comments Sheet - Bottom sheet for post comments
class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  // No mock comments - empty list for production
  final List<Map<String, dynamic>> _comments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InstagramColors.darkTextSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: InstagramColors.darkText,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: InstagramColors.darkText,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(color: InstagramColors.darkSecondary, height: 1),
          // Comments list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                return _buildCommentItem(_comments[index]);
              },
            ),
          ),
          // Comment input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: InstagramColors.primary,
            child: Text(
              comment['username'][5],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: comment['username'],
                        style: const TextStyle(
                          color: InstagramColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: comment['comment'],
                        style: const TextStyle(color: InstagramColors.darkText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      comment['time'],
                      style: const TextStyle(
                        color: InstagramColors.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${comment['likes']} likes',
                      style: const TextStyle(
                        color: InstagramColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Reply',
                      style: TextStyle(
                        color: InstagramColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like button
          GestureDetector(
            onTap: () {
              setState(() {
                comment['isLiked'] = !comment['isLiked'];
                comment['likes'] += comment['isLiked'] ? 1 : -1;
              });
            },
            child: Icon(
              comment['isLiked'] ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: comment['isLiked']
                  ? InstagramColors.red
                  : InstagramColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        border: Border(top: BorderSide(color: InstagramColors.darkSecondary)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: InstagramColors.primary,
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: InstagramColors.darkTextSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: InstagramColors.darkText),
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: InstagramColors.primary),
            onPressed: _isSending
                ? null
                : () async {
                    if (_commentController.text.trim().isNotEmpty) {
                      setState(() => _isSending = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          // Add comment to Firestore
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .add({
                                'userId': user.uid,
                                'username':
                                    user.displayName ??
                                    user.email?.split('@').first,
                                'userAvatar': user.photoURL ?? '',
                                'text': _commentController.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          // Update comment count
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .update({
                                'commentsCount': FieldValue.increment(1),
                              });

                          _commentController.clear();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                      if (mounted) {
                        setState(() => _isSending = false);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

/// Post Detail Screen
class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

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
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Post header
            _buildPostHeader(),
            // Post image
            _buildPostImage(),
            // Actions
            _buildPostActions(context),
            // Likes
            _buildLikesCount(),
            // Caption
            _buildCaption(),
            // Comments preview
            _buildCommentsPreview(context),
            // Time
            _buildTimeAgo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: InstagramColors.primary,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: const Text(
        'username',
        style: TextStyle(
          color: InstagramColors.darkText,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Original Audio',
        style: TextStyle(
          color: InstagramColors.darkTextSecondary,
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: InstagramColors.darkText),
        onPressed: () {},
      ),
    );
  }

  Widget _buildPostImage() {
    return Container(
      height: 400,
      color: InstagramColors.darkSurface,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 100,
          color: InstagramColors.darkTextSecondary,
        ),
      ),
    );
  }

  Widget _buildPostActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.favorite_border,
              size: 28,
              color: InstagramColors.darkText,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => CommentsSheet(postId: '1'),
                isScrollControlled: true,
              );
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 28,
              color: InstagramColors.darkText,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.send_outlined,
            size: 28,
            color: InstagramColors.darkText,
          ),
          const Spacer(),
          const Icon(
            Icons.bookmark_outline,
            size: 28,
            color: InstagramColors.darkText,
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '1,234 likes',
          style: TextStyle(
            color: InstagramColors.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'username ',
                style: const TextStyle(
                  color: InstagramColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    'This is an amazing post! 🔥 Check out my profile for more content.',
                style: const TextStyle(color: InstagramColors.darkText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsPreview(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => CommentsSheet(postId: '1'),
          isScrollControlled: true,
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'View all 42 comments',
            style: TextStyle(color: InstagramColors.darkTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAgo() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '2 hours ago',
          style: TextStyle(
            color: InstagramColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Share Sheet
class ShareSheet extends StatelessWidget {
  final String? postId;

  const ShareSheet({super.key, this.postId});

  @override
  Widget build(BuildContext context) {
    // No mock contacts - empty list for production
    final contacts = <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InstagramColors.darkTextSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: InstagramColors.darkText,
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
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
          const SizedBox(height: 16),
          // Contact list
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: InstagramColors.primary,
                    child: Text(contacts[index][5].toUpperCase()),
                  ),
                  title: Text(
                    contacts[index],
                    style: const TextStyle(color: InstagramColors.darkText),
                  ),
                  subtitle: const Text(
                    'User',
                    style: TextStyle(color: InstagramColors.darkTextSecondary),
                  ),
                  onTap: () {
                    // Share to this user
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

/// Save Post Sheet
class SavePostSheet extends StatelessWidget {
  final String postId;

  const SavePostSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InstagramColors.darkTextSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Options
          _buildOption(Icons.bookmark_outline, 'Save'),
          _buildOption(Icons.link, 'Copy Link'),
          _buildOption(Icons.share_outlined, 'Share to...'),
          _buildOption(Icons.report_outlined, 'Report'),
          const SizedBox(height: 16),
          // Cancel
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: InstagramColors.darkSurface,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: InstagramColors.darkText),
      title: Text(
        label,
        style: const TextStyle(color: InstagramColors.darkText),
      ),
      onTap: () {},
    );
  }
}

/// Like Reaction Picker - Emoji picker for reactions
class LikePicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  const LikePicker({super.key, required this.onReactionSelected});

  static const List<String> _reactions = [
    '❤️',
    '😍',
    '😢',
    '😮',
    '😡',
    '🔥',
    '👏',
    '😎',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: InstagramColors.darkBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _reactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
