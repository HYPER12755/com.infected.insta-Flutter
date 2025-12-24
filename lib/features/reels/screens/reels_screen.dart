
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/reels_provider.dart';
import '../../feed/models/post_model.dart';

class ReelsScreen extends ConsumerWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reels = ref.watch(reelsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reels', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          ),
        ],
      ),
      body: reels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
        data: (posts) {
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // For demonstration, we'll use a network image as a placeholder
              // In a real app, this would be a ReelPlayer widget with a video controller.
              return ReelPlayer(post: post);
            },
          );
        },
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final Post post;
  const ReelPlayer({super.key, required this.post});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  // VideoPlayerController? _controller;

  // In a real app, you would initialize a video controller like this:
  // @override
  // void initState() {
  //   super.initState();
  //   _controller = VideoPlayerController.network(widget.post.videoUrl)
  //     ..initialize().then((_) {
  //       setState(() {});
  //       _controller?.play();
  //       _controller?.setLooping(true);
  //     });
  // }

  // @override
  // void dispose() {
  //   _controller?.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder for the video
        // In a real app, this would be:
        // _controller != null && _controller!.value.isInitialized
        //     ? AspectRatio(
        //         aspectRatio: _controller!.value.aspectRatio,
        //         child: VideoPlayer(_controller!),
        //       )
        //     : const Center(child: CircularProgressIndicator()),
        CachedNetworkImage(
          imageUrl: widget.post.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(76),
                Colors.transparent,
                Colors.black.withAlpha(127),
              ],
              stops: const [0.0, 0.4, 0.9],
            ),
          ),
        ),
        _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(widget.post.userAvatar),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.post.username,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.caption,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Original Audio - ${widget.post.username}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }
}
