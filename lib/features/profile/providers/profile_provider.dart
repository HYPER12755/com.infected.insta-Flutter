import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/data/repositories/post_repository.dart';
import 'package:infected_insta/features/profile/models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

/// Full profile state for a given userId (null = current user)
class ProfileState {
  final User? user;
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final String? error;
  final bool isFollowing;

  const ProfileState({this.user, this.posts = const [], this.isLoading = true, this.error, this.isFollowing = false});

  ProfileState copyWith({User? user, List<Map<String, dynamic>>? posts,
      bool? isLoading, String? error, bool? isFollowing}) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final String? _targetUserId; // null = own profile

  ProfileNotifier(this._userRepo, this._postRepo, this._targetUserId)
      : super(const ProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final uid = _targetUserId ?? _userRepo.getCurrentUserId();
    if (uid == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    final profileResult = await _userRepo.getUserProfile(uid);
    final postsResult = await _postRepo.getUserPosts(uid);

    bool isFollowing = false;
    final currentUserId = _userRepo.getCurrentUserId();
    if (currentUserId != null && _targetUserId != null && currentUserId != _targetUserId) {
      try {
        isFollowing = await _userRepo.isFollowing(currentUserId, _targetUserId!);
      } catch (_) {}
    }

    profileResult.fold(
      (err) => state = state.copyWith(isLoading: false, error: err.message),
      (data) {
        final posts = postsResult.fold((_) => <Map<String, dynamic>>[], (p) => p);

        // Count followers / following from the DB response
        final followerCount = (data['followers_count'] as int?) ?? 0;
        final followingCount = (data['following_count'] as int?) ?? 0;

        state = state.copyWith(
          isLoading: false,
          posts: posts,
          isFollowing: isFollowing,
          user: User(
            userId: uid,
            username: data['username'] ?? 'user',
            name: data['full_name'] ?? data['username'] ?? 'User',
            bio: data['bio'] ?? '',
            website: data['website'] ?? '',
            avatarUrl: data['avatar_url'] ?? '',
            followers: followerCount,
            following: followingCount,
            posts: posts.length,
          ),
        );
      },
    );
  }

  Future<void> followUser(String targetId) async {
    final uid = _userRepo.getCurrentUserId();
    if (uid == null) return;
    state = state.copyWith(isFollowing: true);
    await _userRepo.followUser(uid, targetId);
    await load();
  }

  Future<void> unfollowUser(String targetId) async {
    final uid = _userRepo.getCurrentUserId();
    if (uid == null) return;
    state = state.copyWith(isFollowing: false);
    await _userRepo.unfollowUser(uid, targetId);
    await load();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String bio,
    String website = '',
    String? avatarUrl,
  }) async {
    final uid = _userRepo.getCurrentUserId();
    if (uid == null) return false;

    final data = <String, dynamic>{
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'website': website,
    };
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    final result = await _userRepo.updateUserProfile(uid, data);
    result.fold((_) => null, (_) => load());
    return result.fold((_) => false, (_) => true);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    ref.watch(userRepositoryProvider),
    PostRepository(),
    null, // own profile
  );
});

// Provider for viewing another user's profile by userId
final userProfileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, userId) {
  return ProfileNotifier(ref.watch(userRepositoryProvider), PostRepository(), userId);
});
