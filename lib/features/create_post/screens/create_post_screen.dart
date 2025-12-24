import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../providers/create_post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _sharePost() async {
    final createPostNotifier = ref.read(createPostControllerProvider.notifier);
    await createPostNotifier.createPost(caption: _captionController.text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createPostState = ref.watch(createPostControllerProvider);
    final createPostNotifier = ref.read(createPostControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: createPostNotifier.imageFile != null && !createPostState
                ? _sharePost
                : null,
            child: const Text(
              'Share',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              createPostState
                  ? const LinearProgressIndicator()
                  : const SizedBox(height: 4), // For the space of the indicator
              GestureDetector(
                onTap: () async {
                  await createPostNotifier.pickImage();
                  setState(() {}); // Rebuild to show the image
                },
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: createPostNotifier.imageFile != null
                        ? DecorationImage(
                            image: FileImage(File(createPostNotifier.imageFile!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: createPostNotifier.imageFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select an image',
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              if (createPostNotifier.imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      createPostNotifier.clearImage();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _buildListTile(Icons.location_on_outlined, 'Add Location'),
              const Divider(),
              _buildListTile(Icons.person_add_alt_1_outlined, 'Tag People'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
