import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/posts/models/post.dart';
import '../../../features/posts/repositories/post_repository.dart';
import '../providers/storage_provider.dart';

final createPostRepositoryProvider = Provider(
  (ref) => CreatePostRepository(ref),
);

class CreatePostRepository {
  final Ref _ref;

  CreatePostRepository(this._ref);

  Future<void> createPost({
    required String caption,
    required XFile imageFile,
  }) async {
    final user = _ref.read(authProvider);
    if (user == null) {
      throw Exception('User not logged in');
    }

    final postId = const Uuid().v4();
    final imageUrl = await _uploadImage(imageFile, postId, user.id);

    final post = Post(
      id: postId,
      authorId: user.id,
      imageUrl: imageUrl,
      caption: caption,
      timestamp: DateTime.now(),
    );

    await _ref.read(postRepositoryProvider).createPost(post);
  }

  Future<String> _uploadImage(XFile imageFile, String postId, String userId) async {
    final storageService = _ref.read(storageProvider);
    
    // Generate storage path: user_id/post_id.jpg
    final storagePath = '$userId/$postId.jpg';
    
    // Upload the file and get the public URL
    return await storageService.uploadFile(imageFile.path, storagePath);
  }
}
