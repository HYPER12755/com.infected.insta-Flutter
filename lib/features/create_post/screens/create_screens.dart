import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/features/create_post/providers/storage_provider.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});
  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  XFile? _image;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _image = file);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.image),
          title: const Text('Choose from Gallery'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.camera),
          title: const Text('Take a Photo'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _share() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a photo first')));
      return;
    }

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')));
      return;
    }

    setState(() => _isPosting = true);

    try {
      final storage = SupabaseStorageService(supabase);
      final imgId = const Uuid().v4();
      final storagePath = '$uid/$imgId.jpg';

      // Upload image → get public URL
      final imageUrl = await storage.uploadFile(_image!.path, storagePath);

      // Insert post
      final result = await PostRepository().createPost({
        'user_id': uid,
        'image_url': imageUrl,
        'caption': _captionCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });

      if (!mounted) return;

      result.fold(
        (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${err.message}'))),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post shared!')));
          // Go back to feed
          context.go('/home');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.xmark),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go('/home'),
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _share,
            child: Text('Share',
                style: TextStyle(
                  color: _isPosting ? Colors.white30 : primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ── Image Preview ──────────────────────────────────────────────
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              height: 320,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstagramColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _image != null
                    ? Colors.transparent
                    : InstagramColors.darkSecondary),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(_image!.path), fit: BoxFit.cover,
                          width: double.infinity),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      FaIcon(FontAwesomeIcons.images, size: 56, color: primary.withValues(alpha: 0.6)),
                      const SizedBox(height: 14),
                      Text('Tap to add a photo',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Gallery or Camera',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                    ]),
            ),
          ),

          // ── Caption ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFF2A2A3E),
                  child: const FaIcon(FontAwesomeIcons.user, size: 16, color: Colors.white54)),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _captionCtrl,
                maxLines: 5,
                maxLength: 2200,
                decoration: InputDecoration(
                  hintText: 'Write a caption…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              )),
            ]),
          ),

          const Divider(color: Colors.white12),

          // ── Options ────────────────────────────────────────────────────
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.locationDot, size: 18),
            title: TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'Add location',
                hintStyle: TextStyle(color: InstagramColors.darkTextSecondary),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: InstagramColors.darkText),
            ),
          ),

          const Divider(color: Colors.white12),

          ListTile(
            leading: const FaIcon(FontAwesomeIcons.userTag, size: 18),
            title: const Text('Tag people'),
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14, color: Colors.white38),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tag people — coming in next update'))),
          ),

          const Divider(color: Colors.white12),

          // ── Share button (bottom) ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isPosting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Share Post',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Camera Capture Screen ────────────────────────────────────────────────────
class CameraCaptureScreen extends StatelessWidget {
  const CameraCaptureScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          IconButton(icon: const FaIcon(FontAwesomeIcons.boltLightning, color: Colors.white),
              onPressed: () {}),  // Flash toggle — requires camera plugin
        ]),
        const Expanded(child: Center(child: FaIcon(FontAwesomeIcons.camera,
            size: 80, color: Colors.white24))),
        Padding(padding: const EdgeInsets.all(24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            const FaIcon(FontAwesomeIcons.images, color: Colors.white, size: 28),
            GestureDetector(
              onTap: () async {
                final file = await ImagePicker().pickImage(source: ImageSource.camera);
                if (file != null && context.mounted) Navigator.pop(context, file);
              },
              child: Container(width: 72, height: 72, decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4))),
            ),
            const FaIcon(FontAwesomeIcons.rotate, color: Colors.white, size: 28),
          ])),
      ])),
    );
  }
}

// ── Edit/Crop Screen ─────────────────────────────────────────────────────────
class EditCropScreen extends StatelessWidget {
  const EditCropScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text('Edit'),
        actions: [
          TextButton(
            onPressed: () => context.push('/create'),
            child: const Text('Next', style: TextStyle(color: InstagramColors.primary,
                fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(children: [
        const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.cropSimple, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('Select a photo to edit', style: TextStyle(color: Colors.white38)),
          ]))),
        SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text('Crop & filter tools available after selecting a photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        )),
      ]),
    );
  }
}

// ── Gallery Picker Sheet ─────────────────────────────────────────────────────
class GalleryPickerSheet extends StatelessWidget {
  const GalleryPickerSheet({super.key});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: InstagramColors.darkBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: Column(children: [
      const SizedBox(height: 16),
      const Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemCount: 12,
        itemBuilder: (_, i) => Container(color: Colors.white10,
            child: const FaIcon(FontAwesomeIcons.image, color: Colors.white24)),
      )),
    ]),
  );
}
