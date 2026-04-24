import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';
import 'package:infected_insta/core/widgets/rich_caption.dart';

// ─── Post Detail Screen ───────────────────────────────────────────────────────
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _postRepo = PostRepository();
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _postRepo.getPost(widget.postId);
    final uid = supabase.auth.currentUser?.id;
    result.fold(
      (_) => setState(() => _isLoading = false),
      (post) async {
        final liked = uid != null
            ? await _postRepo.isPostLikedByUser(widget.postId, uid)
            : false;
        if (mounted) {
          setState(() {
            _post = {
              ...post,
              'username': post['username'] ?? 'user',
              'userAvatar': post['userAvatar'] ?? '',
              'imageUrl': post['imageUrl'] ?? post['image_url'] ?? '',
              'likes': post['likes'] ?? 0,
              'commentsCount': post['commentsCount'] ?? 0,
            };
            _isLiked = liked;
            _isSaved = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _toggleLike() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _post!['likes'] = (_post!['likes'] as int) + (_isLiked ? 1 : -1);
    });
    if (_isLiked) {
      await _postRepo.likePost(widget.postId, uid);
    } else {
      await _postRepo.unlikePost(widget.postId, uid);
    }
  }

  Future<void> _toggleSave() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isSaved = !_isSaved);
    if (_isSaved) {
      await _postRepo.savePost(widget.postId, uid);
    } else {
      await _postRepo.unsavePost(widget.postId, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: InstagramColors.darkBackground,
        appBar: AppBar(backgroundColor: InstagramColors.darkBackground,
            title: const Text('Post')),
        body: const PostCardSkeleton(),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: InstagramColors.darkBackground,
        appBar: AppBar(backgroundColor: InstagramColors.darkBackground,
            title: const Text('Post')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation,
                color: Colors.white54, size: 40),
            const SizedBox(height: 16),
            const Text('Post not found', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: Text('Retry',
                style: TextStyle(color: primary))),
          ],
        )),
      );
    }

    final post = _post!;
    final imageUrl = post['imageUrl'] as String? ?? '';
    final username = post['username'] as String? ?? 'user';
    final userAvatar = post['userAvatar'] as String? ?? '';
    final caption = post['caption'] as String? ?? '';
    final location = post['location'] as String? ?? '';
    final likes = post['likes'] as int? ?? 0;
    final commentsCount = post['commentsCount'] as int? ?? 0;

    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.ellipsis, size: 20),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          ListTile(
            leading: GestureDetector(
              onTap: () => context.push('/profile/$username'),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2A2A3E),
                backgroundImage: userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(userAvatar) as ImageProvider
                    : null,
                child: userAvatar.isEmpty
                    ? const FaIcon(FontAwesomeIcons.user, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            title: GestureDetector(
              onTap: () => context.push('/profile/$username'),
              child: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            subtitle: location.isNotEmpty
                ? Text(location, style: const TextStyle(
                    color: InstagramColors.darkTextSecondary, fontSize: 12))
                : null,
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.ellipsis, size: 18),
              onPressed: () => _showOptions(context),
            ),
          ),

          // Image
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: _isLiked ? null : _toggleLike,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                placeholder: (_, __) => Container(
                  height: 380,
                  color: const Color(0xFF1E1E2E),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 380,
                  color: const Color(0xFF1E1E2E),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.image, color: Colors.white24, size: 48)),
                ),
              ),
            ),

          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              GestureDetector(
                onTap: _toggleLike,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: FaIcon(
                    key: ValueKey(_isLiked),
                    _isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                    size: 26,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showComments(context),
                child: const FaIcon(FontAwesomeIcons.comment, size: 24),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _sharePost(context),
                child: const FaIcon(FontAwesomeIcons.paperPlane, size: 24),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSave,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: FaIcon(
                    key: ValueKey(_isSaved),
                    _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                    size: 24,
                    color: _isSaved ? primary : Colors.white,
                  ),
                ),
              ),
            ]),
          ),

          // Likes
          if (likes > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: GestureDetector(
                onTap: () => context.push('/likes/${widget.postId}'),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${_fmtCount(likes)} likes',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          // Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _buildCaption(username, caption, context),
            ),

          // View all comments
          if (commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: GestureDetector(
                onTap: () => _showComments(context),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('View all $commentsCount comments',
                      style: const TextStyle(color: InstagramColors.darkTextSecondary)),
                ),
              ),
            ),

          // Time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_fmtTime(post['created_at']),
                  style: const TextStyle(
                      color: InstagramColors.darkTextSecondary, fontSize: 11)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCaption(String username, String caption, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: RichCaption(username: username, caption: caption, maxLines: 10),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsBottomSheet(postId: widget.postId),
    );
  }

  void _sharePost(BuildContext context) {
    Clipboard.setData(
        ClipboardData(text: 'https://infected.app/post/${widget.postId}'));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _showOptions(BuildContext context) {
    final uid = supabase.auth.currentUser?.id;
    final isOwn = _post?['user_id'] == uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (isOwn)
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _postRepo.deletePost(widget.postId);
                if (context.mounted) context.pop();
              },
            )
          else
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.flag),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Post reported')));
              },
            ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.link),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              _sharePost(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      )),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return 'just now';
    final t = raw is String ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'just now';
  }
}

// ─── Comments Bottom Sheet ────────────────────────────────────────────────────
class _CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsBottomSheet({required this.postId});

  @override
  ConsumerState<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<_CommentsBottomSheet> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _postRepo = PostRepository();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _replyingTo = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _postRepo.getComments(widget.postId);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isLoading = false),
        (c) => setState(() { _comments = c; _isLoading = false; }),
      );
    }
  }

  Future<void> _send() async {
    final raw = _ctrl.text.trim();
    final text = _replyingTo.isNotEmpty ? '@$_replyingTo $raw' : raw;
    if (raw.isEmpty || _isSending) return;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _isSending = true);
    _ctrl.clear();
    final result = await _postRepo.addComment(
        postId: widget.postId, userId: uid, text: text);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isSending = false),
        (c) => setState(() { _comments.add(c); _isSending = false; }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            GestureDetector(onTap: () => Navigator.pop(context),
                child: const FaIcon(FontAwesomeIcons.xmark, size: 18)),
          ]),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: _isLoading
              ? ListView.builder(itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: UserTileSkeleton()))
              : _comments.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.comment,
                            size: 40, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text('No comments yet',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                        const SizedBox(height: 4),
                        Text('Be first to comment!',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 12)),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _buildComment(_comments[i]),
                    ),
        ),
        _buildInput(),
      ]),
    );
  }

  Widget _buildComment(Map<String, dynamic> c) {
    final avatar = c['avatar'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF2A2A3E),
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
          child: avatar.isEmpty
              ? const FaIcon(FontAwesomeIcons.user, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: '${c['username'] ?? ''} ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            TextSpan(text: c['text'] ?? c['comment'] ?? '',
                style: const TextStyle(fontSize: 13)),
          ])),
          const SizedBox(height: 4),
          Row(children: [
            Text(_fmtTime(c['created_at']),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_focusNode);
                setState(() => _replyingTo = c['username'] as String? ?? '');
              },
              child: Text('Reply',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5))),
            ),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(child: Row(children: [
        const CircleAvatar(radius: 16, backgroundColor: Color(0xFFC039FF),
            child: FaIcon(FontAwesomeIcons.user, size: 13)),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _ctrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _replyingTo.isNotEmpty ? 'Replying to @$_replyingTo…' : 'Add a comment…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            border: InputBorder.none, contentPadding: EdgeInsets.zero,
          ),
        )),
        _isSending
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: FaIcon(FontAwesomeIcons.paperPlane,
                    size: 18,
                    color: _ctrl.text.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Colors.white.withValues(alpha: 0.25)),
                onPressed: _send,
              ),
      ])),
    );
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return 'now';
    final t = raw is String ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    final d = DateTime.now().difference(t);
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}

// ─── Who Liked Screen ─────────────────────────────────────────────────────────
class LikesCommentsScreen extends StatefulWidget {
  final String type; // 'likes' or 'comments'
  final String postId;
  const LikesCommentsScreen({super.key, required this.type, required this.postId});

  @override
  State<LikesCommentsScreen> createState() => _LikesCommentsScreenState();
}

class _LikesCommentsScreenState extends State<LikesCommentsScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await supabase
          .from('post_likes')
          .select('user_id, profiles!post_likes_user_id_fkey(username, avatar_url)')
          .eq('post_id', widget.postId);
      if (mounted) {
        setState(() {
          _users = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return {
              'username': p['username'] ?? 'user',
              'avatar': p['avatar_url'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text(widget.type == 'likes' ? 'Likes' : 'Comments'),
      ),
      body: _isLoading
          ? ListView.builder(itemCount: 6,
              itemBuilder: (_, __) => const UserTileSkeleton())
          : _users.isEmpty
              ? Center(child: Text('No ${widget.type} yet',
                  style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final avatar = u['avatar'] as String? ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2A2A3E),
                        backgroundImage: avatar.isNotEmpty
                            ? CachedNetworkImageProvider(avatar) as ImageProvider : null,
                        child: avatar.isEmpty
                            ? const FaIcon(FontAwesomeIcons.user, size: 14) : null,
                      ),
                      title: Text(u['username'] ?? ''),
                      onTap: () => context.push('/profile/${u['username']}'),
                    );
                  },
                ),
    );
  }
}

// ─── Stubs (satisfy router references) ────────────────────────────────────────
class CommentsSheet extends StatelessWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context) =>
      _CommentsBottomSheet(postId: postId);
}

class ShareSheet extends StatelessWidget {
  final String? postId;
  const ShareSheet({super.key, this.postId});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class SavePostSheet extends StatelessWidget {
  final String postId;
  const SavePostSheet({super.key, required this.postId});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class LikePicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  const LikePicker({super.key, required this.onReactionSelected});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
