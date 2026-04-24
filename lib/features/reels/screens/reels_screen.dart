import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import 'package:infected_insta/features/feed/screens/post_screens.dart';
import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/features/feed/models/post_model.dart';
import 'package:infected_insta/features/reels/providers/reels_provider.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

class ReelsScreen extends ConsumerWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reels = ref.watch(reelsProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reels',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            onPressed: () => context.push('/story-camera'),
          ),
        ],
      ),
      body: reels.when(
        loading: () => const FeedSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e',
            style: const TextStyle(color: Colors.white))),
        data: (posts) => posts.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.film, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('No reels yet', style: TextStyle(color: Colors.white54)),
                ]))
            : PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: posts.length,
                itemBuilder: (_, i) => _ReelCard(post: posts[i]),
              ),
      ),
    );
  }
}

class _ReelCard extends StatefulWidget {
  final Post post;
  const _ReelCard({required this.post});

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  VideoPlayerController? _videoCtrl;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFollowing = false;
  bool _showHeart = false;
  final _postRepo = PostRepository();
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _initVideo();
    _checkLike();
  }

  Future<void> _initVideo() async {
    // Try to load video if video_url is available
    final videoUrl = widget.post.imageUrl; // In reels, imageUrl may be a video
    if (videoUrl.endsWith('.mp4') || videoUrl.contains('video')) {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoCtrl!.play();
            _videoCtrl!.setLooping(true);
          }
        });
    }
  }

  Future<void> _checkLike() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final liked = await _postRepo.isPostLikedByUser(widget.post.id, uid);
    final following = await _userRepo.isFollowing(uid, widget.post.id);
    if (mounted) setState(() { _isLiked = liked; _isFollowing = following; });
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) setState(() => _showHeart = false); });
    if (_isLiked) {
      await _postRepo.likePost(widget.post.id, uid);
    } else {
      await _postRepo.unlikePost(widget.post.id, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _toggleLike,
      child: Stack(fit: StackFit.expand, children: [
        // ── Video or image ──
        _videoCtrl != null && _videoCtrl!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoCtrl!.value.size.width,
                  height: _videoCtrl!.value.size.height,
                  child: VideoPlayer(_videoCtrl!),
                ),
              )
            : widget.post.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(borderRadius: 0),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
                  )
                : Container(color: const Color(0xFF1A1A2E)),

        // ── Gradient overlays ──
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent,
                Colors.black87],
            stops: [0, 0.5, 1],
          ),
        )),

        // ── Double-tap heart flash ──
        if (_showHeart)
          const Center(child: Icon(Icons.favorite, color: Colors.white,
              size: 100)),

        // ── Right action bar ──
        Positioned(
          right: 12, bottom: 100,
          child: Column(children: [
            _ActionBtn(
              icon: _isLiked
                  ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              label: _fmtCount(widget.post.likes + (_isLiked ? 1 : 0)),
              color: _isLiked ? Colors.red : Colors.white,
              onTap: _toggleLike,
            ),
            const SizedBox(height: 20),
            _ActionBtn(
              icon: FontAwesomeIcons.comment,
              label: _fmtCount(widget.post.comments),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentsSheet(postId: widget.post.id),
              ),
            ),
            const SizedBox(height: 20),
            _ActionBtn(
              icon: FontAwesomeIcons.paperPlane,
              label: 'Share',
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'https://infected.app/post/${widget.post.id}'));
              },
            ),
            const SizedBox(height: 20),
            _ActionBtn(
              icon: _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
              label: '',
              color: _isSaved ? const Color(0xFFC039FF) : Colors.white,
              onTap: () async {
                final uid = supabase.auth.currentUser?.id;
                if (uid == null) return;
                setState(() => _isSaved = !_isSaved);
                if (_isSaved) {
                  await _postRepo.savePost(widget.post.id, uid);
                } else {
                  await _postRepo.unsavePost(widget.post.id, uid);
                }
              },
            ),
          ]),
        ),

        // ── Bottom info ──
        Positioned(
          left: 16, right: 80, bottom: 60,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@${widget.post.username}',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
            if (widget.post.caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(widget.post.caption,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const FaIcon(FontAwesomeIcons.music, size: 12, color: Colors.white70),
              const SizedBox(width: 6),
              Text('Original Audio · ${widget.post.username}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),

        // ── Video progress ──
        if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: VideoProgressIndicator(_videoCtrl!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: const Color(0xFFC039FF),
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white10,
                )),
          ),
      ]),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        FaIcon(icon, color: color, size: 28),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}
