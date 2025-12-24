import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../repositories/post_repository.dart';

final postsProvider = StreamProvider<List<Post>>((ref) {
  return ref.watch(postRepositoryProvider).getPosts();
});
