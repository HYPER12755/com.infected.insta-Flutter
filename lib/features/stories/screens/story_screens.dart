import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:infected_insta/features/create_post/providers/storage_provider.dart';
import 'package:infected_insta/data/repositories/message_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

// ─── Story Viewer ─────────────────────────────────────────────────────────────
class StoryViewerScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String? userAvatar;
  final List<String> storyImages;

  const StoryViewerScreen({
    super.key,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.storyImages,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<String> _loadedImages = [];
  late AnimationController _progressCtrl;
  bool _isPaused = false;
  final _replyCtrl = TextEditingController();

  static const _storyDuration = Duration(seconds: 5);

  List<String> get _images => _loadedImages.isNotEmpty
      ? _loadedImages
      : widget.storyImages;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _images.length - 1) {
      setState(() => _currentIndex++);
      _progressCtrl
        ..reset()
        ..forward();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressCtrl
        ..reset()
        ..forward();
    }
  }

  void _pause() {
    _progressCtrl.stop();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (widget.storyImages.isEmpty) {
      return; // No stories to display
    } else {
      _loadedImages = widget.storyImages;
      _progressCtrl.forward();
    }
    setState(() => _isPaused = false);
  }

  void _showReplySheet(BuildContext ctx) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16),
        child: Row(children: [
          Expanded(child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Reply to ${widget.username}…',
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          )),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFC039FF)),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              _resume();
              try {
                final uid = supabase.auth.currentUser?.id;
                if (uid == null) return;
                final repo = MessageRepository();
                final convResult = await repo.getOrCreateConversation(uid, widget.userId);
                convResult.fold(
                  (err) {},
                  (convId) async {
                    await repo.sendMessage(convId, {'text': "↩ ${widget.username}'s story: $text"});
                  },
                );
              } catch (e) { }
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // ── Image ──
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (d) {
              if (d.globalPosition.dx < w / 2) {
                _prev() ;
              } else {
                _next();
              }
            },
            onLongPressStart: (_) => _pause(),
            onLongPressEnd: (_) => _resume(),
            child: CachedNetworkImage(
              imageUrl: _images[_currentIndex],
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A2E),
                  child: const Center(child: FaIcon(FontAwesomeIcons.image,
                      color: Colors.white24, size: 60))),
            ),
          ),
        ),

        // ── Gradient overlay top ──
        Positioned(
          top: 0, left: 0, right: 0,
          height: 160,
          child: Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          )),
        ),

        // ── Progress bars ──
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(children: List.generate(_images.length, (i) {
              return Expanded(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 2.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: i < _currentIndex
                      ? const LinearProgressIndicator(value: 1,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation(Colors.white))
                      : i == _currentIndex
                          ? AnimatedBuilder(
                              animation: _progressCtrl,
                              builder: (_, __) => LinearProgressIndicator(
                                value: _progressCtrl.value,
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ))
                          : const LinearProgressIndicator(value: 0,
                              backgroundColor: Colors.white30,
                              valueColor: AlwaysStoppedAnimation(Colors.white)),
                ),
              ));
            })),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2A2A3E),
                backgroundImage: (widget.userAvatar?.isNotEmpty == true)
                    ? CachedNetworkImageProvider(widget.userAvatar!) : null,
                child: (widget.userAvatar?.isEmpty != false)
                    ? const FaIcon(FontAwesomeIcons.user, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.username,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text('${_currentIndex + 1}/${_images.length}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              )),
              if (_isPaused)
                const FaIcon(FontAwesomeIcons.pause, color: Colors.white, size: 16),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.ellipsisVertical,
                    color: Colors.white, size: 18),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A2E),
                  builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(leading: const Icon(Icons.flag), title: const Text('Report story'),
                      onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story reported'))); }),
                    ListTile(leading: const Icon(Icons.volume_off), title: const Text('Mute'),
                      onTap: () { Navigator.pop(context); }),
                  ])),
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
        ])),

        // ── Reply bar ──
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: _pause,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white60),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text('Reply to ${widget.username}…',
                      style: const TextStyle(color: Colors.white60)),
                ),
              )),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('❤️', style: TextStyle(fontSize: 22)),
                ),
              ),
            ]),
          )),
        ),
      ]),
    );
  }
}

// ─── Story Create Screen ──────────────────────────────────────────────────────
class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  XFile? _image;
  bool _isUploading = false;

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _upload() async {
    if (_image == null) return;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _isUploading = true);
    try {
      final storage = SupabaseStorageService(supabase);
      final path = 'stories/$uid/${const Uuid().v4()}.jpg';
      final url = await storage.uploadFile(_image!.path, path, bucket: 'stories');

      await supabase.from('stories').insert({
        'user_id': uid,
        'image_url': url,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Story posted!')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Stack(children: [
        // Preview
        if (_image != null)
          Positioned.fill(
            child: Image.file(File(_image!.path), fit: BoxFit.cover))
        else
          Positioned.fill(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.camera, size: 60, color: Colors.white38),
              const SizedBox(height: 20),
              const Text('Add to Your Story',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Share a photo that disappears in 24 hours',
                  style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _pickBtn(FontAwesomeIcons.images, 'Gallery',
                    () => _pick(ImageSource.gallery)),
                const SizedBox(width: 24),
                _pickBtn(FontAwesomeIcons.camera, 'Camera',
                    () => _pick(ImageSource.camera)),
              ]),
            ],
          )),

        // Top bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          if (_image != null)
            TextButton(
              onPressed: () => setState(() => _image = null),
              child: const Text('Change', style: TextStyle(color: Colors.white)),
            ),
        ]),

        // Bottom bar
        if (_image != null)
          Positioned(bottom: 24, left: 16, right: 16,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC039FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isUploading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                        SizedBox(width: 8),
                        Text('Share to Story',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ]),
            ),
          ),
      ])),
    );
  }

  Widget _pickBtn(FaIconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }
}

// ─── Story Camera Screen ──────────────────────────────────────────────────────
class StoryCameraScreen extends StatelessWidget {
  const StoryCameraScreen({super.key});

  @override
  Widget build(BuildContext context) => const StoryCreateScreen();
}

// ─── Story Highlights Screen ──────────────────────────────────────────────────
class StoryHighlightsScreen extends StatelessWidget {
  const StoryHighlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Highlights'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: () => context.push('/story-create'),
          ),
        ],
      ),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const FaIcon(FontAwesomeIcons.circlePlay, size: 56, color: Colors.white24),
        const SizedBox(height: 16),
        const Text('No Highlights Yet', style: TextStyle(
            color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Create highlights from your stories to keep them on your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.push('/story-create'),
          child: const Text('Add Highlight'),
        ),
      ])),
    );
  }
}
