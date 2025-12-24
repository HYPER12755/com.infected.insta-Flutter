import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/create_post_repository.dart';

final createPostControllerProvider = StateNotifierProvider<CreatePostController, bool>((ref) {
  return CreatePostController(ref);
});

class CreatePostController extends StateNotifier<bool> {
  final Ref _ref;

  CreatePostController(this._ref) : super(false);

XFile? _imageFile;

  XFile? get imageFile => _imageFile;

  Future<void> createPost({
    required String caption,
  }) async {
    if (_imageFile == null) {
      return;
    }

    state = true;
    try {
      await _ref.read(createPostRepositoryProvider).createPost(
            caption: caption,
            imageFile: _imageFile!,
          );
    } finally {
      state = false;
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _imageFile = pickedFile;
    }
  }

  void clearImage() {
    _imageFile = null;
  }
}
