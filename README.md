# 🟣 Infected — Premium Social Media App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.9+-blue?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?style=flat-square&logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green?style=flat-square&logo=supabase)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20%7C%20Web-lightgrey?style=flat-square)

A **production-ready** Instagram-parity social media app built with Flutter and Supabase. Dark purple theme, real-time everything, WebRTC calls.

</div>

---

## ✨ Features

### 🔐 Auth
- Email/password sign-up + validation + auto profile creation (DB trigger)
- Google OAuth + GitHub OAuth
- Password reset via email
- 3-page animated onboarding with suggested follows

### 📱 Feed
- Infinite scroll with real Supabase data
- Double-tap heart burst animation (like)
- Optimistic like / save (instant UI, DB sync)
- **Tappable #hashtags and @mentions** in captions (navigate to tag/profile)
- Expand/collapse long captions ("more")
- Post ellipsis: Delete (own) / Report / Not interested / Copy link
- Share post sheet (send as DM, copy link)
- Pull-to-refresh, shimmer skeleton loading

### 📖 Stories
- Animated per-segment progress bars
- Multi-story per user support
- Real stories loaded from DB (filtered by `expires_at > now()`)
- Long-press pause, tap sides navigate
- Reply sends real DM (`getOrCreateConversation` → `sendMessage`)
- Ellipsis menu: Report / Mute
- Upload to Supabase Storage `stories` bucket (24hr DB expiry)
- Story create from camera / gallery

### 🎬 Reels
- Vertical swipe PageView
- `video_player` with image fallback
- Like / save (optimistic) / share (copies link to clipboard)
- Comment sheet (real DB data)
- **Follow / Following toggle** button per reel
- **Tappable captions** (#hashtag / @mention)

### 💬 Messages (full Instagram DM parity)
- **Notes** top of inbox — 60-char, 24hr, posts to `notes` table
- Conversation search (debounced)
- Unread **purple glow** on avatar, online dot
- Last message preview (`📷 Photo`, `🎤 Voice message`, `You:` prefix)
- Video call quick-action button in each conversation tile
- Real-time stream via Supabase `.stream()`
- **Swipe-right reply** (stores reply_to_id / reply_text / reply_sender in DB)
- **Message reactions** (❤️ 😂 😮 😢 😡 👍 — long-press)
- **Voice messages** — real recording with `record` package, real playback with `just_audio` + live waveform progress
- **Unsend** (sets `is_deleted: true`)
- Image sending (gallery pick → Supabase Storage → image bubble)
- Typing indicator (3-dot bounce, sent to `typing_indicators` table)
- Date dividers (Today / Yesterday / date)
- Read receipts (✓ / ✓✓ / ✓✓ blue)

### 📞 Calls
- WebRTC P2P via `flutter_webrtc`
- Metered TURN relay — **STUN first, TURN fallback only** (`iceCandidatePoolSize: 0`)
- Supabase Realtime broadcast for signaling (DB polling fallback)
- `listenForIncomingCalls()` streams `calls` table for real incoming call detection
- Outgoing: pulsing purple avatar, mute/speaker buttons wired
- Incoming: pulsing green ring, haptic feedback, accept/decline navigates to call
- In-call: draggable PiP local video, mute/video/speaker/flip all wired, auto-hide controls

### 🔍 Explore
- Real-time debounced search (350ms) — excludes already-followed users
- Staggered 3-column explore grid
- Trending hashtags extracted from post captions
- Follow / unfollow from search results (optimistic)

### 🔔 Notifications
- Grouped by time (Today / This Week / Earlier)
- Type icons — ❤️ like, 💬 comment, 👤 follow, @ mention
- Follow Back inline (optimistic)
- Follow requests: Accept / Decline
- Mark all read on open
- Realtime unread red dot on bell icon

### 👤 Profile
- Own + other users' profiles (`/profile/:username` resolves username → UUID)
- **Follow / Unfollow toggle** with correct `isFollowing` state loaded from DB
- **Message button** opens real DM conversation (`getOrCreateConversation`)
- Block user (writes to `blocks` table), Report user
- Avatar upload to `avatars` bucket
- Bio, **website link** (tappable, copies to clipboard)
- Post grid (3-col) + tagged posts grid (both real DB)
- Followers / Following count → navigates to list
- Edit profile: name, username, bio, website, avatar

### ⚙️ Settings
- Change password (real `supabase.auth.updateUser`)
- Personal info screen
- Blocked accounts list with unblock
- Private / notifications / theme toggles
- Logout confirmation

### 📤 Create Post
- Camera or gallery pick
- Upload to `posts` bucket → insert to `posts` table
- Caption, location, tag people
- Refreshes profile on success

---

## 🛠 Tech Stack

| | |
|---|---|
| Framework | Flutter 3.9+ / Dart 3 |
| State | Riverpod 2.x |
| Navigation | GoRouter 17 |
| Backend | Supabase (Auth, Postgres, Realtime, Storage) |
| Calls | flutter_webrtc + Metered TURN |
| Voice | record 5.x + just_audio 0.9 |
| Auth | Supabase Auth + Google Sign-In 7 |
| UI | Material 3, Google Fonts (Inter), Font Awesome |
| Images | cached_network_image |
| Media | image_picker, video_player |

---

## 📁 Structure

```
lib/
├── core/
│   ├── config/app_config.dart
│   ├── theme/instagram_theme.dart
│   └── widgets/
│       ├── shimmer.dart
│       └── rich_caption.dart       ← tappable hashtags + mentions
├── data/
│   ├── models/result.dart
│   └── repositories/
│       ├── base_repository.dart
│       ├── message_repository.dart
│       ├── notification_repository.dart
│       ├── post_repository.dart
│       └── user_repository.dart
├── features/
│   ├── activity/   notifications, follow requests
│   ├── auth/       login, signup, onboarding, forgot password
│   ├── call/       WebRTC screens, signaling service, provider
│   ├── chat/       DM inbox, chat screen, voice messages, notes
│   ├── create_post/ image upload, caption
│   ├── extra/      saved, archive, tagged, followers/following
│   ├── feed/       post model, post detail, comments
│   ├── home/       main scaffold, glass nav, feed tab
│   ├── profile/    profile screen, edit, providers
│   ├── reels/      vertical video feed
│   ├── search/     explore grid, hashtag search
│   ├── settings/   settings, change password, blocked
│   ├── splash/     auth redirect
│   └── stories/    story viewer, create, highlights
├── main.dart
├── router.dart     (30+ routes)
└── supabase/supabase_client.dart
```

---

## 🚀 Quick Start

```bash
git clone <repo-url>
cd com.infected.insta-Flutter
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://mrvggotawuxvopjhfagb.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

See [docs/SETUP.md](docs/SETUP.md) for full setup including Google OAuth, GitHub OAuth, and TURN server configuration.

---

## 📚 Docs

| | |
|---|---|
| [docs/SETUP.md](docs/SETUP.md) | Environment setup, OAuth, TURN, Play Store |
| [docs/SUPABASE.md](docs/SUPABASE.md) | Full SQL schema, RLS, triggers, Storage |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code structure, state, real-time patterns |
| [docs/API.md](docs/API.md) | All repository methods + data models |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Standards, PR checklist |

---

**App ID:** `com.infected.insta` | **Region:** `ap-southeast-1`
