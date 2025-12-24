import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostState {
  final File? imageFile;
  final bool isLoading;

  CreatePostState({this.imageFile, this.isLoading = false});

  CreatePostState copyWith({
    File? imageFile,
    bool? isLoading,
  }) {
    return CreatePostState(
      imageFile: imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier() : super(CreatePostState());

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      state = state.copyWith(imageFile: File(pickedFile.path));
    }
  }

  void clearImage() {
    state = state.copyWith(imageFile: null);
  }
}

final createPostProvider = StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier();
});
