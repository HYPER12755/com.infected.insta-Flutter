# Architecture

## Overview

Infected follows a **Feature-First Clean Architecture** with Riverpod for state management and GoRouter for navigation. Each feature is a self-contained vertical slice.

```
lib/
├── core/           # Shared: config, theme, common widgets
├── data/           # Repositories + models (no UI)
├── features/       # One folder per feature
├── main.dart       # Bootstrap
├── router.dart     # All routes (GoRouter)
└── supabase/       # Supabase client singleton
```

---

## State Management

**Riverpod 2.x** — the single source of truth.

| Provider type | Used for |
|---|---|
| `StateNotifierProvider` | Profile, Settings, Call — mutable state with methods |
| `FutureProvider` | One-shot async data (search results, reels list) |
| `StreamProvider` | Real-time data (notification count, DM count) |
| `Provider` | Pure dependencies (repositories, services) |

The `provider` package is used **only** for `SettingsProvider` (ChangeNotifier), kept for the `MaterialApp.router` theme binding. Everything else is Riverpod.

---

## Navigation

**GoRouter 17** with auth redirect guard:

```dart
redirect: (context, state) {
  final isLoggedIn = supabase.auth.currentSession != null;
  if (!isLoggedIn && !isAuthRoute) return '/auth';
  if (isLoggedIn && isAuthRoute)  return '/home';
  return null;
}
```

All 30+ named routes are defined in `router.dart`. Deep-link OAuth callbacks are handled via intent filters on Android (`com.infected.insta://auth/callback`).

---

## Data Layer

All database access goes through **repository classes** that extend `BaseRepository`:

```dart
abstract class BaseRepository {
  User? get currentUser => supabase.auth.currentUser;
  Future<Result<T>> withRetry<T>(Future<T> Function() op, {int maxRetries = 3});
}
```

All repository methods return `Result<T>` — a sealed class:

```dart
sealed class Result<T> { ... }
class Success<T> extends Result<T> { final T data; }
class Failure<T> extends Result<T> { final AppException error; }
```

Callers use `.fold(onError, onSuccess)` — no try/catch at the UI layer.

---

## Real-time Architecture

Supabase **`.stream()`** is used for real-time data — it internally creates a Realtime subscription and returns a Dart `Stream` that emits on every DB change:

```dart
// Messages — live stream
supabase.from('messages')
  .stream(primaryKey: ['id'])
  .eq('conversation_id', id)
  .order('created_at')
  .map(...)

// Notifications count
supabase.from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', uid)
  .map((rows) => rows.where((r) => r['is_read'] != true).length)
```

The call signaling service (`SupabaseSignalingService`) uses Supabase Realtime **broadcast channels** with a database polling fallback.

---

## WebRTC Call Architecture

```
Caller                  Supabase DB             Callee
  │                         │                     │
  │── createCall() ─────────┼────────────────────>│
  │                         │   call_signals row   │
  │<─────────────────────────────── call-request ──│
  │                         │                     │
  │── acceptCall() ─────────┼────────────────────>│
  │<──────────────── SDP offer ──────────────────>│
  │── SDP answer ──────────>│                     │
  │<──────────────── ICE candidates ─────────────>│
  │═══════════════════ WebRTC P2P ════════════════│
```

ICE server priority: host → STUN → TURN (Metered free-tier). `iceCandidatePoolSize: 0` prevents pre-fetching TURN credentials.

---

## UI System

All screens use a **dark theme** with:
- Background: `#0D0D1A`
- Surface: `#1A1A2E`
- Primary: `#C039FF` (purple)
- Glass nav bar: `BackdropFilter` blur + white overlay

The bottom nav bar has **5 items** (Instagram-style): Home / Search / + / Reels / Profile.
Messages (DMs) is accessed via the **paper-plane icon in the feed app bar** (top-right), with a purple unread dot badge.

Skeleton loading is implemented via `ShimmerBox` / `PostCardSkeleton` / `UserTileSkeleton` in `lib/core/widgets/shimmer.dart`.

---

## Rich Caption Widget

`lib/core/widgets/rich_caption.dart` — shared across feed, post detail, and reels. Parses captions with regex, renders `#hashtag` and `@mention` as blue tappable spans via `TapGestureRecognizer`. Expands long captions inline with a "more" link.

## Profile Routing

The router passes `:username` (a string) to `ProfileScreen(userId:)`. `UserRepository.getUserProfile()` detects whether the input is a UUID (regex match) or username string and queries accordingly — no extra round-trip needed.

## Follow State

`ProfileState.isFollowing` is loaded in `ProfileNotifier.load()` by querying the `follows` table. When viewing another user's profile, `userProfileProvider(targetId)` is used — not `profileProvider` — so each viewed profile has its own isolated state.

## Key Design Decisions

**No mock/fixture data in production** — all screens load real Supabase data or show proper empty states.

**Optimistic updates** — like, save, follow all update UI immediately then sync to DB, reverting on error.

**Result<T> everywhere** — no raw exceptions propagating to UI. Every repository method returns `Success<T>` or `Failure<T>`.

**Single Supabase client** — `lib/supabase/supabase_client.dart` exports a single `supabase` global used across all repositories.

**Feature-first over layer-first** — `lib/features/feed/` contains models, providers, and screens rather than separate `lib/models/`, `lib/providers/` directories.
