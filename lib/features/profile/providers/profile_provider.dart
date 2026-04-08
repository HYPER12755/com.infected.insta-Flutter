import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infected_insta/data/repositories/user_repository.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final profileProvider = FutureProvider<User>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final currentUserId = userRepo.getCurrentUserId();

  if (currentUserId == null) {
    throw Exception('User not authenticated');
  }

  final result = await userRepo.getUserProfile(currentUserId);

  return result.fold(
    (error) {
      // Propagate error - no fallback to mock data in production
      throw Exception(error.message);
    },
    (userData) {
      return User(
        userId: currentUserId,
        username: userData['username'] ?? 'username',
        name: userData['fullName'] ?? userData['username'] ?? 'User',
        bio: userData['bio'] ?? '',
        avatarUrl: userData['profilePicture'] ?? '',
        followers: (userData['followers'] as List?)?.length ?? 0,
        following: (userData['following'] as List?)?.length ?? 0,
        posts: userData['posts'] ?? 0,
      );
    },
  );
});
