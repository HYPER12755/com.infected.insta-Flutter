# API Documentation

This document provides a complete reference for the InstaClone application's data models, services, and API interfaces.

## Table of Contents

1. [Models](#models)
2. [Providers](#providers)
3. [Repositories](#repositories)
4. [Services](#services)
5. [Router](#router)

---

## Models

### User Model

```dart
// lib/features/auth/models/user.dart
class User {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  
  User({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### Post Model

```dart
// lib/features/feed/models/post_model.dart
class Post {
  final String id;
  final String username;
  final String userAvatar;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
  
  Post({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });
}
```

### Call Model

```dart
// lib/features/call/models/call_model.dart

enum CallType { audio, video }

enum CallStatus { ringing, accepted, declined, ended, cancelled }

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final CallType callType;
  final CallStatus status;
  final DateTime timestamp;
  final String roomId;
  final String? offerSdp;
  final String? answerSdp;
  final List<Map<String, dynamic>> iceCandidates;
  
  CallModel({
    String? callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    required this.callType,
    this.status = CallStatus.ringing,
    DateTime? timestamp,
    String? roomId,
    this.offerSdp,
    this.answerSdp,
    List<Map<String, dynamic>>? iceCandidates,
  });
  
  factory CallModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  CallModel copyWith({ ... }) { ... }
  bool get isActive => status == CallStatus.ringing || status == CallStatus.accepted;
  bool isCaller(String userId) => callerId == userId;
}
```

### Result Wrapper

```dart
// lib/data/models/result.dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
}
```

---

## Providers

### AuthProvider

```dart
// lib/features/auth/providers/auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabase));
});

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isAuthenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;
  
  Future<void> signIn(String email, String password) async { ... }
  Future<void> signUp(String email, String password, String username) async { ... }
  Future<void> signOut() async { ... }
  Future<void> resetPassword(String email) async { ... }
  Future<void> signInWithGoogle() async { ... }
}
```

**Usage:**

```dart
// In a widget
final authState = ref.watch(authProvider);

if (authState.isAuthenticated) {
  final user = authState.user;
  // Display user info
}

// Sign in
ref.read(authProvider.notifier).signIn('email', 'password');
```

### FeedProvider

```dart
// lib/features/feed/providers/feed_provider.dart
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(supabase));
});

class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
}

class FeedNotifier extends StateNotifier<FeedState> {
  Future<void> loadPosts() async { ... }
  Future<void> refresh() async { ... }
  Future<void> likePost(String postId) async { ... }
}
```

### ProfileProvider

```dart
// lib/features/profile/application/profile_provider.dart
final profileProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, userId) {
  return ProfileNotifier(ref.read(supabase), userId);
});

class ProfileState {
  final UserModel? profile;
  final List<Post> posts;
  final bool isLoading;
  final bool isFollowing;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  Future<void> loadProfile() async { ... }
  Future<void> loadPosts() async { ... }
  Future<void> followUser() async { ... }
  Future<void> unfollowUser() async { ... }
}
```

### CallProvider

```dart
// lib/features/call/providers/call_provider.dart
final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref.read(supabase));
});

class CallState {
  final CallModel? activeCall;
  final bool isInCall;
  final CallType? callType;
  final String? error;
}

class CallNotifier extends StateNotifier<CallState> {
  Future<void> initiateCall(String calleeId, CallType type) async { ... }
  Future<void> acceptCall(String callId) async { ... }
  Future<void> declineCall(String callId) async { ... }
  Future<void> endCall() async { ... }
  Future<void> toggleMute() async { ... }
  Future<void> toggleCamera() async { ... }
}
```

### MessageProvider

```dart
// lib/data/repositories/message_repository.dart
class MessageRepository {
  final SupabaseClient _supabase;
  
  Future<List<Conversation>> getConversations() async { ... }
  Future<List<Message>> getMessages(String conversationId) async { ... }
  Stream<List<Message>> watchMessages(String conversationId) { ... }
  Future<void> sendMessage(String conversationId, String content) async { ... }
  Future<void> markAsRead(String conversationId) async { ... }
}
```

### NotificationProvider

```dart
// lib/data/repositories/notification_repository.dart
class NotificationRepository {
  final SupabaseClient _supabase;
  
  Future<List<Notification>> getNotifications() async { ... }
  Stream<List<Notification>> watchNotifications() { ... }
  Future<void> markAsRead(String notificationId) async { ... }
  Future<void> markAllAsRead() async { ... }
}
```

---

## Repositories

### PostRepository

```dart
// lib/data/repositories/post_repository.dart
class PostRepository {
  final SupabaseClient _supabase;
  
  Future<List<Post>> getFeedPosts({int limit = 20, int offset = 0}) async { ... }
  Future<Post> getPost(String postId) async { ... }
  Future<Post> createPost(String imageUrl, String caption) async { ... }
  Future<void> deletePost(String postId) async { ... }
  Future<void> likePost(String postId) async { ... }
  Future<void> unlikePost(String postId) async { ... }
}
```

### UserRepository

```dart
// lib/data/repositories/user_repository.dart
class UserRepository {
  final SupabaseClient _supabase;
  
  Future<UserModel> getCurrentUser() async { ... }
  Future<UserModel> getUser(String userId) async { ... }
  Future<List<UserModel>> searchUsers(String query) async { ... }
  Future<void> updateProfile(Map<String, dynamic> updates) async { ... }
  Future<void> followUser(String userId) async { ... }
  Future<void> unfollowUser(String userId) async { ... }
  Future<List<UserModel>> getFollowers(String userId) async { ... }
  Future<List<UserModel>> getFollowing(String userId) async { ... }
}
```

### BaseRepository

```dart
// lib/data/repositories/base_repository.dart
class BaseRepository {
  final SupabaseClient _supabase;
  
  // Common query methods
  Future<List<T>> list<T>(String table, { 
    String? orderBy, 
    bool ascending = false,
    int? limit,
    int? offset,
    Map<String, dynamic>? filters,
  }) async { ... }
  
  Future<T> get<T>(String table, String id) async { ... }
  
  Future<T> create<T>(String table, Map<String, dynamic> data) async { ... }
  
  Future<void> update(String table, String id, Map<String, dynamic> data) async { ... }
  
  Future<void> delete(String table, String id) async { ... }
  
  Stream<List<T>> watch<T>(String table, { Map<String, dynamic>? filters }) { ... }
}
```

---

## Services

### RealtimeMessagesService

```dart
// lib/data/realtime/realtime_messages_service.dart
class RealtimeMessagesService {
  final SupabaseClient _supabase;
  
  /// Watch messages in a conversation
  Stream<List<Message>> watchMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId);
  }
  
  /// Watch new messages only
  Stream<Message> watchNewMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((messages) => messages.last);
  }
}
```

### RealtimeNotificationsService

```dart
// lib/data/realtime/realtime_notifications_service.dart
class RealtimeNotificationsService {
  final SupabaseClient _supabase;
  
  /// Watch notifications for current user
  Stream<List<Notification>> watchNotifications(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
```

### PresenceService

```dart
// lib/data/realtime/presence_service.dart
class PresenceService {
  final SupabaseClient _supabase;
  
  /// Track user presence
  Future<void> trackPresence(String userId) async {
    await supabase.channel('presence').track({'user_id': userId});
  }
  
  /// Stop tracking presence
  Future<void> stopTracking() async {
    await supabase.channel('presence').untrack();
  }
  
  /// Watch presence changes
  Stream<Map<String, dynamic>> watchPresence() {
    return supabase.channel('presence').onPresenceSync(
      (payload) => payload.newState,
    );
  }
}
```

### RealtimeFeedService

```dart
// lib/data/realtime/realtime_feed_service.dart
class RealtimeFeedService {
  final SupabaseClient _supabase;
  
  /// Watch new posts in feed
  Stream<List<Post>> watchFeed({int limit = 20}) {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit);
  }
}
```

### SupabaseSignalingService

```dart
// lib/features/call/services/supabase_signaling_service.dart
class SupabaseSignalingService {
  final SupabaseClient _supabase;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  
  /// Initialize renderers
  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }
  
  /// Create WebRTC peer connection
  Future<void> createPeerConnection() async {
    _pc = await createPeerConnection(_configuration);
    // Handle ICE candidates
    _pc!.onIceCandidate = (candidate) {
      // Send to remote peer via Supabase
    };
  }
  
  /// Handle incoming offer
  Future<void> handleOffer(String offer) async { ... }
  
  /// Handle incoming answer
  Future<void> handleAnswer(String answer) async { ... }
  
  /// Handle ICE candidate
  Future<void> handleIceCandidate(String candidate) async { ... }
  
  /// Send offer via Supabase Realtime
  Future<void> sendOffer(CallModel call) async { ... }
  
  /// Send answer via Supabase Realtime
  Future<void> sendAnswer(CallModel call) async { ... }
  
  /// Clean up resources
  Future<void> dispose() async {
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    await _pc?.close();
  }
}
```

### StorageProvider

```dart
// lib/features/create_post/providers/storage_provider.dart
class StorageProvider {
  final SupabaseClient _supabase;
  
  /// Upload image to posts bucket
  Future<String> uploadPostImage(String filePath, String userId) async {
    final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final response = await supabase.storage
        .from('posts')
        .upload(fileName, File(filePath));
    return response.path;
  }
  
  /// Get public URL for uploaded file
  String getPublicUrl(String path) {
    return supabase.storage.from('posts').getPublicUrl(path);
  }
  
  /// Delete uploaded file
  Future<void> deleteFile(String path) async {
    await supabase.storage.from('posts').remove([path]);
  }
}
```

---

## Router

The app uses GoRouter for navigation with auth guards:

```dart
// lib/router.dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentSession != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup';
    
    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    // Auth routes
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const AuthScreen()),
    
    // Main app
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    
    // Post details
    GoRoute(
      path: '/post/:id',
      builder: (context, state) => PostDetailScreen(
        postId: state.pathParameters['id']!,
      ),
    ),
    
    // Messages
    GoRoute(
      path: '/messages',
      builder: (_, __) => const MessagesInboxScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ConversationChatScreen(
        conversationId: state.pathParameters['id']!,
      ),
    ),
    
    // Calls
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CallScreen(
          calleeId: extra?['calleeId'],
          callType: extra?['callType'],
        );
      },
    ),
    GoRoute(
      path: '/video-call',
      builder: (_, __) => const VideoCallScreen(),
    ),
    
    // Profile
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (_, __) => const EditProfileScreen(),
    ),
  ],
);
```

### Route Parameters

| Route | Parameters | Description |
|-------|------------|-------------|
| `/post/:id` | `id` (String) | Post details |
| `/chat/:id` | `id` (String) | Conversation ID |
| `/profile` | - | Current user's profile |
| `/profile/:id` | `id` (String) | Other user's profile |
| `/story/:userId` | `userId` (String) | User's stories |
| `/search/:query` | `query` (String) | Search results |

---

## Error Handling

All API calls use the `Result` wrapper for type-safe error handling:

```dart
final result = await postRepository.getFeedPosts();

result.when(
  success: (posts) => print('Got ${posts.length} posts'),
  failure: (error) => print('Error: $error'),
);

// Or use extension
if (result.isSuccess) {
  final posts = result.dataOrNull;
}
```

---

## Next Steps

- [Contributing Guide](CONTRIBUTING.md) - Development workflow
- [Supabase Setup](SUPABASE.md) - Database configuration