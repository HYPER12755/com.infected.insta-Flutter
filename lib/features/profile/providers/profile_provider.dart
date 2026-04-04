import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

final profileProvider = FutureProvider<User>((ref) async {
  // Simulate a network request
  await Future.delayed(const Duration(seconds: 2));

  return User(
    userId: 'test_user_id',
    username: 'testuser',
    name: 'Test User',
    bio: 'This is a test bio.',
    avatarUrl: 'https://picsum.photos/200',
    followers: 1234,
    following: 567,
    posts: 12,
  );
});
