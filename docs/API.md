# API Reference

Complete reference for all repository methods and data models.

---

## Data Models

### Post (feed/models/post_model.dart)
```dart
class Post {
  final String id;
  final String username;
  final String userAvatar;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
}
```

### User (profile/models/user_model.dart)
```dart
class User {
  final String userId;
  final String username;
  final String name;
  final String bio;
  final String website;   // ← new
  final String avatarUrl;
  final int followers;
  final int following;
  final int posts;
}
```

### ProfileState (profile/providers/profile_provider.dart)
```dart
class ProfileState {
  final User? user;
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final String? error;
  final bool isFollowing;   // ← whether current user follows this profile
}
```

### CallModel (call/models/call_model.dart)
```dart
class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final CallType callType;   // audio | video
  final CallStatus status;   // ringing | accepted | declined | ended | cancelled
  final DateTime timestamp;
  final String roomId;
}
```

### Result<T> (data/models/result.dart)
```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T data; }
class Failure<T> extends Result<T> {
  final AppException error; // DatabaseException | NotFoundException | etc.
}
// Usage:
result.fold(
  (error) => handleError(error.message),
  (data)  => useData(data),
);
```

---

## PostRepository

```dart
// Get paginated feed (joins profiles, post_likes count, comments count)
Future<Result<List<Map<String, dynamic>>>> getPosts({int limit = 30})

// Get a single post
Future<Result<Map<String, dynamic>>> getPost(String postId)

// Get all posts by a user
Future<Result<List<Map<String, dynamic>>>> getUserPosts(String userId)

// Paginated with cursor
Future<Result<List<Map<String, dynamic>>>> getPostsPaginated({
  String? lastDoc,
  int limit = 20,
})

// CRUD
Future<Result<String>> createPost(Map<String, dynamic> postData)
Future<Result<void>> deletePost(String postId)

// Likes
Future<Result<void>> likePost(String postId, String userId)
Future<Result<void>> unlikePost(String postId, String userId)
Future<bool> isPostLikedByUser(String postId, String userId)

// Saves
Future<Result<void>> savePost(String postId, String userId)
Future<Result<void>> unsavePost(String postId, String userId)

// Comments
Future<Result<List<Map<String, dynamic>>>> getComments(String postId)
Future<Result<Map<String, dynamic>>> addComment({
  required String postId,
  required String userId,
  required String text,
})
```

**Post map fields** (returned by `getPosts`):

| Field | Type | Source |
|---|---|---|
| `id` | String | posts.id |
| `user_id` | String | posts.user_id |
| `username` | String | profiles.username (joined) |
| `userAvatar` | String | profiles.avatar_url (joined) |
| `imageUrl` | String | posts.image_url (normalised) |
| `caption` | String | posts.caption |
| `location` | String | posts.location |
| `likes` | int | post_likes.count (joined) |
| `commentsCount` | int | comments.count (joined) |
| `created_at` | String | posts.created_at |

---

## UserRepository

```dart
// Resolve username string to profile (used by router)
Future<Result<Map<String, dynamic>>> getUserByUsername(String username)

// Handles both UUID and username string inputs
Future<Result<Map<String, dynamic>>> getUserProfile(String userIdOrUsername)

// Check if follower follows target
Future<bool> isFollowing(String followerId, String followingId)

String? getCurrentUserId()
User? getCurrentUser()
bool isAuthenticated()

// Profile CRUD
Future<Result<Map<String, dynamic>>> getUserProfile(String userId)
// Returns profile + followers_count + following_count

Future<Result<void>> updateUserProfile(String userId, Map<String, dynamic> data)
Future<Result<void>> createUserProfile(String userId, Map<String, dynamic> userData)

// Social graph
Future<Result<void>> followUser(String currentUserId, String targetUserId)
Future<Result<void>> unfollowUser(String currentUserId, String targetUserId)

// Discovery
Future<Result<List<Map<String, dynamic>>>> searchUsers(String query)
Future<Result<List<Map<String, dynamic>>>> getSuggestedUsers(String currentUserId)
```

---

## MessageRepository

```dart
// Conversations
Future<Result<List<Map<String, dynamic>>>> getConversations(String userId)
Future<Result<String>> getOrCreateConversation(String userId1, String userId2)
Future<Result<String>> createConversation(List<String> participants)

// Messages (real-time stream)
Stream<List<Map<String, dynamic>>> getMessagesStream(
  String conversationId, String currentUserId)
// Each message map includes: id, sender_id, text, is_read, is_deleted,
//   reply_text, reply_sender, reactions, isMe, created_at

// Send
Future<Result<void>> sendMessage(String conversationId, Map<String, dynamic> data)
// data keys: text, reply_to_id, reply_text, reply_sender

// Receipts
Future<void> markConversationRead(String conversationId, String userId)

// Typing
Future<void> sendTyping(String conversationId, String userId, bool isTyping)
Stream<bool> watchTyping(String conversationId, String otherUserId)

// Unread count
Stream<int> getUnreadCount(String userId)
```

---

## NotificationRepository

```dart
// Real-time stream of all notifications for a user
Stream<Result<List<Map<String, dynamic>>>> getNotifications(String userId)

// Management
Future<Result<void>> markAsRead(String notificationId)
Future<Result<void>> markAllAsRead(String userId)
Future<Result<int>> getUnreadCount(String userId)
Future<Result<void>> createNotification(Map<String, dynamic> data)
Future<Result<void>> deleteNotification(String notificationId)
```

**Notification map fields:**

| Field | Type | Values |
|---|---|---|
| `type` | String | `like` \| `comment` \| `follow` \| `mention` |
| `actor_id` | String | Triggering user ID |
| `actor_username` | String | — |
| `actor_avatar` | String | — |
| `post_id` | String? | For like/comment notifications |
| `post_image` | String? | Thumbnail URL |
| `comment_text` | String? | For comment notifications |
| `is_read` | bool | — |

---

## AuthRepository

```dart
// Current user
User? get currentUser
Session? get currentSession
Stream<AuthState> get authStateChanges

// Email / password
Future<AuthResponse> signInWithEmailAndPassword(String email, String password)
Future<AuthResponse> signUpWithEmailAndPassword({
  required String email,
  required String password,
  required String username,
  required String fullName,
})

// OAuth
Future<bool> signInWithGoogle()
Future<bool> signInWithGitHub()

// Account
Future<void> sendPasswordResetEmail(String email)
Future<void> signOut()

// Profile helpers
Future<Map<String, dynamic>?> getUserById(String userId)
Future<void> updateUserProfile({
  required String userId,
  required Map<String, dynamic> data,
})
```

---

## SupabaseStorageService

```dart
// Upload file, returns public URL
Future<String> uploadFile(
  String filePath,
  String storagePath, {
  String bucket = 'posts',    // or 'avatars', 'stories', 'messages'
})

String getPublicUrl(String storagePath, {String bucket = 'posts'})
Future<void> deleteFile(String storagePath, {String bucket = 'posts'})
```

---

## Providers

```dart
// Auth
final authRepositoryProvider = Provider<AuthRepository>
final authStateChangesProvider = StreamProvider<AuthState>
final currentUserProvider = Provider<User?>

// Profile
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>
final userProfileProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>

// Settings
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>

// Reels / Search
final reelsProvider = FutureProvider<List<Post>>
final searchProvider = FutureProvider<List<Post>>

// Call
final callProvider = StateNotifierProvider<CallProvider, CallState>
final signalingServiceProvider = Provider<SupabaseSignalingService>
```
