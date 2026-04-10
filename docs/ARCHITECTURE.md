# Architecture Overview

This document provides a comprehensive overview of the InstaClone application architecture, including the tech stack, design patterns, and system components.

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Architecture Pattern](#architecture-pattern)
3. [Project Structure](#project-structure)
4. [Core Components](#core-components)
5. [State Management](#state-management)
6. [Data Flow](#data-flow)
7. [Security](#security)

---

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Flutter | 3.9.x |
| Language | Dart | 3.x |
| State Management | Riverpod / Flutter Riverpod | 2.6.1 |
| Navigation | GoRouter | 17.0.1 |
| Backend | Supabase | Latest |
| Video/Audio | WebRTC (flutter_webrtc) | 1.4.1 |
| Code Generation | Freezed, JSON Serializable | 3.x |
| DI | GetIt | 9.2.0 |
| UI | Material Design 3 | Built-in |

### Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^17.0.1
  supabase_flutter: ^2.0.0
  flutter_webrtc: ^1.4.1
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  go_router: ^17.0.1
  get_it: ^9.2.0
  image_picker: ^1.2.1
  cached_network_image: ^3.4.1
```

---

## Architecture Pattern

The application follows a **Clean Architecture** pattern with three main layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (Screens, Widgets, Providers, View Models)                │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                              │
│  (Entities, Use Cases, Repository Interfaces)              │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                                │
│  (Repositories, Data Sources, Models, API Clients)         │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer** - UI components, state management, user interactions
2. **Domain Layer** - Business logic, entities, use cases
3. **Data Layer** - API calls, data transformation, caching

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── router.dart                  # GoRouter configuration
│
├── core/                        # Core utilities and shared code
│   ├── config/                  # App configuration (AppConfig)
│   ├── theme/                  # Theme definitions
│   │   ├── instagram_theme.dart
│   │   └── theme.dart
│   └── widgets/                # Shared reusable widgets
│       └── glass_widgets.dart
│
├── data/                        # Data layer
│   ├── fixtures/               # Mock data for development
│   ├── models/                # Data models
│   ├── realtime/              # Real-time services
│   │   ├── presence_service.dart
│   │   ├── realtime_feed_service.dart
│   │   ├── realtime_messages_service.dart
│   │   └── realtime_notifications_service.dart
│   └── repositories/          # Repository implementations
│       ├── base_repository.dart
│       ├── message_repository.dart
│       ├── notification_repository.dart
│       ├── post_repository.dart
│       └── user_repository.dart
│
├── features/                   # Feature modules (domain + presentation)
│   ├── activity/              # Notifications/Activity
│   ├── auth/                  # Authentication
│   │   ├── data/              # Auth data layer
│   │   ├── models/            # Auth models
│   │   ├── presentation/      # Auth UI
│   │   │   ├── providers.dart
│   │   │   ├── login_form.dart
│   │   │   ├── signup_form.dart
│   │   │   └── ...
│   │   ├── providers/         # Auth state providers
│   │   └── repositories/      # Auth repositories
│   ├── call/                  # Video/Audio calls
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── chat/                  # Messaging
│   ├── create_post/           # Post creation
│   ├── feed/                  # Main feed
│   ├── home/                  # Home screen with bottom nav
│   ├── profile/               # User profile
│   ├── reels/                 # Short-form video
│   ├── search/                # Search and explore
│   ├── settings/              # App settings
│   └── stories/               # Stories feature
│
└── supabase/                  # Supabase client setup
    └── supabase_client.dart
```

---

## Core Components

### 1. Navigation (GoRouter)

The app uses GoRouter for declarative routing with authentication guards:

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Auth check - redirect unauthenticated users
    final isLoggedIn = supabase.auth.currentSession != null;
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    return null;
  },
  routes: [...],
);
```

**Route Groups:**
- `/auth`, `/login`, `/signup` - Authentication routes
- `/home` - Main app with tab navigation
- `/post/:id` - Post details
- `/messages`, `/chat/:id` - Messaging
- `/call`, `/video-call` - Video calls
- `/story/:userId` - Story viewer

### 2. State Management (Riverpod)

All state is managed through Riverpod providers:

```dart
// Example provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabase));
});
```

**Provider Types Used:**
- `StateNotifierProvider` - For complex state with actions
- `FutureProvider` - For async data fetching
- `StreamProvider` - For real-time data (Supabase streams)
- `Provider` - For dependency injection

### 3. Supabase Integration

The app uses Supabase for all backend services:

```dart
// supabase_client.dart
class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}

final supabase = Supabase.instance.client;
```

**Supabase Features Used:**
- **Auth** - Email/password, Google OAuth
- **Database** - PostgreSQL with RLS
- **Realtime** - Presence, subscriptions
- **Storage** - Media uploads

### 4. Real-time Services

Real-time functionality is handled by specialized services:

```dart
// Realtime presence tracking
class PresenceService {
  Future<void> trackPresence(String userId) async {
    await supabase.channel('presence').track({'user_id': userId});
  }
}

// Realtime messages
class RealtimeMessagesService {
  Stream<List<Message>> watchMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId);
  }
}
```

### 5. WebRTC Calls

Video/audio calls use WebRTC via Supabase Realtime signaling:

```dart
// Signaling service
class SupabaseSignalingService {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  Future<void> initialize() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // WebRTC peer connection management
  Future<void> createPeerConnection() async {
    _pc = await createPeerConnection(_configuration);
  }
}
```

---

## State Management

### Provider Hierarchy

```
App
├── AppConfigProvider          # App-wide configuration
├── ThemeProvider              # Theme state (light/dark)
├── AuthProvider               # Authentication state
│   ├── UserProvider           # Current user data
│   └── SessionProvider        # Session state
├── FeedProvider               # Main feed posts
├── MessageProvider            # Conversations & messages
├── CallProvider               # Active call state
├── NotificationProvider       # Notifications
└── ProfileProvider            # User profiles
```

### State Flow

```
User Action
    │
    ▼
Provider (StateNotifier)
    │
    ▼
Repository (Data Layer)
    │
    ▼
Supabase Client / API
    │
    ▼
State Update -> UI Rebuild
```

---

## Data Flow

### Authentication Flow

```
1. User enters credentials
2. AuthProvider.signIn(email, password)
3. Supabase.auth.signInWithPassword()
4. Session stored in memory
5. Auth state updated
6. Router redirects to home
```

### Post Creation Flow

```
1. User selects media (image/video)
2. Image picker captures content
3. CreatePostProvider processes media
4. StorageProvider uploads to Supabase Storage
5. CreatePostRepository saves post metadata
6. FeedProvider.refresh() updates feed
```

### Real-time Message Flow

```
1. User opens conversation
2. RealtimeMessagesService subscribes to channel
3. Supabase sends new messages via Postgres changes
4. MessageProvider updates state
5. UI automatically rebuilds
```

---

## Security

### Authentication Security

- Supabase Auth handles all authentication
- JWT tokens stored securely by Supabase SDK
- Session validation on app startup
- Auth guards on protected routes

### Row Level Security (RLS)

All database tables use Supabase RLS policies:

```sql
-- Example: Only show user's own posts
CREATE POLICY "Users can view own posts"
ON posts FOR SELECT
USING (auth.uid() = user_id);
```

### API Key Protection

- Anonymous key (anon key) used for client-side operations
- Service role key never exposed to client
- Environment variables for sensitive config

### Local Storage

- No sensitive data stored locally
- Theme preferences stored in SharedPreferences
- Auth tokens managed by Supabase SDK

---

## Performance Considerations

### Optimizations Implemented

1. **Image Caching** - `cached_network_image` for efficient image loading
2. **Lazy Loading** - Pagination on feed and search results
3. **Virtualized Lists** - Efficient rendering of large lists
4. **Connection Pooling** - Supabase client reuse
5. **Code Splitting** - Feature-based lazy loading

### Build Optimization

```bash
# Enable tree shaking
flutter build apk --split-per-abi

# Release build optimizations
flutter build release --no-tree-shake-icons
```

---

## Testing Strategy

The project follows testing best practices:

- **Unit Tests** - Providers, repositories, services
- **Widget Tests** - UI components
- **Integration Tests** - Full user flows

---

## Environment Configuration

Configuration is managed through environment variables:

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
```

---

## Further Reading

- [Setup Guide](SETUP.md) - Detailed setup instructions
- [Supabase Guide](SUPABASE.md) - Database and backend setup
- [API Documentation](API.md) - Complete API reference
- [Contributing Guide](CONTRIBUTING.md) - Development workflow