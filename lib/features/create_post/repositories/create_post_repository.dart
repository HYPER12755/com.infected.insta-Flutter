import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/posts/models/post.dart';
import '../../../features/posts/repositories/post_repository.dart';
import '../providers/storage_provider.dart';

final createPostRepositoryProvider = Provider((ref) => CreatePostRepository(ref));

class CreatePostRepository {
  final Ref _ref;

  CreatePostRepository(this._ref);

  Future<void> createPost({
    required String caption,
    required XFile imageFile,
  }) async {
    final user = _ref.read(authProvider).currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final postId = const Uuid().v4();
    final imageUrl = await _uploadImage(imageFile, postId);

    final post = Post(
      id: postId,
      authorId: user.uid,
      imageUrl: imageUrl,
      caption: caption,
      timestamp: DateTime.now(),
    );

    await _ref.read(postRepositoryProvider).createPost(post);
  }

  Future<String> _uploadImage(XFile imageFile, String postId) async {
    final storageRef = _ref.read(storageProvider).ref().child('posts').child(postId);
    final uploadTask = await storageRef.putFile(File(imageFile.path));
    return await uploadTask.ref.getDownloadURL();
  }
}
