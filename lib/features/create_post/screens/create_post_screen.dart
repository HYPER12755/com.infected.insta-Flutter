
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/create_post_provider.dart';

class CreatePostScreen extends ConsumerWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createPostState = ref.watch(createPostProvider);
    final createPostNotifier = ref.read(createPostProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: createPostState.imageFile != null ? () {} : null,
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
              GestureDetector(
                onTap: () => createPostNotifier.pickImage(),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: createPostState.imageFile != null
                        ? DecorationImage(
                            image: FileImage(createPostState.imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: createPostState.imageFile == null
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
              if (createPostState.imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: () => createPostNotifier.clearImage(),
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
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
