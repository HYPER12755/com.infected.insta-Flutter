import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Create Post Screen - Main create post UI
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isPosting = false;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null || _captionController.text.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      // Upload image to Firebase Storage
      final postId = const Uuid().v4();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(postId);
      final uploadTask = await storageRef.putFile(File(_selectedImage!.path));
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Save post to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'username': user.displayName ?? user.email?.split('@').first,
        'userAvatar': user.photoURL ?? '',
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'likes': 0,
        'likedBy': [],
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

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
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _createPost,
            child: Text(
              'Share',
              style: TextStyle(
                color: _isPosting
                    ? InstagramColors.darkTextSecondary
                    : InstagramColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image/Video preview area
            GestureDetector(
              onTap: _openGallery,
              child: Container(
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InstagramColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: InstagramColors.darkSecondary),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 60,
                      color: InstagramColors.darkTextSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tap to add photo or video',
                      style: TextStyle(
                        color: InstagramColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Caption input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                maxLength: 2200,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: TextStyle(
                    color: InstagramColors.darkTextSecondary,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: InstagramColors.darkText),
              ),
            ),
            const Divider(color: InstagramColors.darkSecondary),
            // Options
            ListTile(
              leading: const Icon(
                Icons.person_add_outlined,
                color: InstagramColors.darkText,
              ),
              title: const Text(
                'Tag people',
                style: TextStyle(color: InstagramColors.darkText),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: InstagramColors.darkTextSecondary,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: InstagramColors.darkText,
              ),
              title: const Text(
                'Add location',
                style: TextStyle(color: InstagramColors.darkText),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: InstagramColors.darkTextSecondary,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.music_note_outlined,
                color: InstagramColors.darkText,
              ),
              title: const Text(
                'Add music',
                style: TextStyle(color: InstagramColors.darkText),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: InstagramColors.darkTextSecondary,
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _openGallery() {
    _pickImage();
  }

  void _createPost() {
    _uploadPost();
  }
}

/// Gallery Picker Sheet
class GalleryPickerSheet extends StatelessWidget {
  const GalleryPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: InstagramColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: InstagramColors.darkText,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: InstagramColors.darkText,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Open camera
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.select_all,
                        color: InstagramColors.primary,
                      ),
                      onPressed: () {
                        // Multi-select mode
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.primaries[index % Colors.primaries.length]
                      .withOpacity(0.2),
                  child: const Icon(Icons.image, color: Colors.white54),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Camera Capture Screen
class CameraCaptureScreen extends StatelessWidget {
  const CameraCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.flash_off, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            // Camera preview
            const Expanded(
              child: Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 100,
                  color: Colors.white38,
                ),
              ),
            ),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  // Capture button
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Flip camera
                  const Icon(
                    Icons.flip_camera_ios_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit/Crop Screen
class EditCropScreen extends StatefulWidget {
  const EditCropScreen({super.key});

  @override
  State<EditCropScreen> createState() => _EditCropScreenState();
}

class _EditCropScreenState extends State<EditCropScreen> {
  String _selectedFilter = 'Original';

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'color': null},
    {'name': 'Clarendon', 'color': Colors.blueGrey.withOpacity(0.3)},
    {'name': 'Gingham', 'color': Colors.brown.withOpacity(0.2)},
    {'name': 'Moon', 'color': Colors.grey.withOpacity(0.4)},
    {'name': 'Lark', 'color': Colors.orange.withOpacity(0.2)},
    {'name': 'Reyes', 'color': Colors.pink.withOpacity(0.2)},
  ];

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
        title: const Text('Edit'),
        actions: [
          TextButton(
            onPressed: () {
              // Next
            },
            child: const Text(
              'Next',
              style: TextStyle(
                color: InstagramColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with filter
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _filters.firstWhere(
                      (f) => f['name'] == _selectedFilter,
                    )['color'] ??
                    InstagramColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 100, color: Colors.white38),
              ),
            ),
          ),
          // Edit tools
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildEditTool(Icons.crop, 'Crop'),
                _buildEditTool(Icons.rotate_right, 'Rotate'),
                _buildEditTool(Icons.tune, 'Adjust'),
              ],
            ),
          ),
          // Filters
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter['name'] == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter['name']),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color:
                                filter['color'] ?? InstagramColors.darkSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: InstagramColors.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter['name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? InstagramColors.primary
                                : InstagramColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTool(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: InstagramColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: InstagramColors.darkText),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: InstagramColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
