# Setup Guide

Complete guide to get Infected running on your machine.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | 3.9+ | [flutter.dev/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.x | Bundled with Flutter |
| Android Studio | Latest | Android SDK + emulator |
| VS Code | Any | With Flutter + Dart extensions |
| Git | 2.x | — |

**Android requirements:** API 24+ device or emulator (WebRTC needs API 24).

---

## 1. Clone & Install

```bash
git clone <repo-url>
cd com.infected.insta-Flutter
flutter pub get
```

---

## 2. Configure Supabase

### Option A — Edit source (simplest for dev)

Open `lib/core/config/app_config.dart` and update:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### Option B — Build-time defines (recommended for CI/CD)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhb...
```

### Option C — `.env` via direnv / secrets

```bash
export SUPABASE_URL=https://YOUR_PROJECT.supabase.co
export SUPABASE_ANON_KEY=eyJhb...
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## 3. Set Up the Database

Run the complete SQL schema from [docs/SUPABASE.md](SUPABASE.md) in your Supabase SQL editor. This creates all tables, triggers, RLS policies, and Storage buckets.

---

## 4. Android Setup

Everything is pre-configured in `android/app/build.gradle.kts`:

- `applicationId = "com.infected.insta"`
- `minSdk = 24` (WebRTC requirement)
- NDK pinned to `27.0.12077973`
- Core library desugaring enabled
- ProGuard enabled for release

**For release builds**, create `android/key.properties` and update `build.gradle.kts` signing config:

```properties
# android/key.properties (DO NOT commit this file)
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/path/to/your.keystore
```

Then update `build.gradle.kts` `release` block to reference it.

---

## 5. Google Sign-In Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → Create project
2. **APIs & Services → OAuth consent screen** → External → fill details
3. **Credentials → Create OAuth Client ID → Android**
   - Package name: `com.infected.insta`
   - SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
4. Copy the Web Client ID
5. In Supabase: **Authentication → Providers → Google → Enable** → paste Client ID + Secret
6. Add redirect URI: `com.infected.insta://auth/callback`

---

## 6. GitHub OAuth Setup

1. [github.com/settings/developers](https://github.com/settings/developers) → New OAuth App
2. Homepage URL: `https://YOUR_PROJECT.supabase.co`
3. Callback URL: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
4. Copy Client ID + Secret
5. In Supabase: **Authentication → Providers → GitHub → Enable** → paste credentials

---

## 7. TURN Servers (WebRTC calls)

Pre-configured with Metered free-tier credentials:

```
Username: 1575304bdb73d5dd86d6f997
Password: yszsvsDGGtvh3TfI
```

Free tier = 500 MB/month relay bandwidth. TURN is only used when direct P2P fails (`iceTransportPolicy: 'all'`, `iceCandidatePoolSize: 0`). Most calls on the same WiFi never consume quota.

To upgrade: replace credentials in `lib/features/call/services/supabase_signaling_service.dart`.

---

## 8. Run the App

```bash
# Debug (hot reload available)
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release

# Linux desktop
flutter run -d linux

# Web
flutter run -d chrome
```

---

## 9. Storage Buckets

Create these buckets in **Supabase → Storage**:

| Bucket | Public | Purpose |
|--------|--------|---------|
| `posts` | ✅ | Post images |
| `avatars` | ✅ | Profile avatars |
| `stories` | ✅ | Story images (24hr) |
| `messages` | ✅ | DM images + voice messages |

---

## Troubleshooting

**`minSdkVersion` conflict**
```
flutter clean && flutter pub get
```

**WebRTC camera/mic not working on Android emulator**
Use a physical device — emulators don't support WebRTC media.

**`SUPABASE_URL` error on start**
The app validates the URL on init. Check `AppConfig.supabaseUrl` is set.

**Build fails with NDK error**
NDK `27.0.12077973` must be installed. In Android Studio: SDK Manager → SDK Tools → NDK → install that version.

**Google Sign-In `PlatformException`**
- SHA-1 fingerprint must match in Google Cloud Console
- Package name must be `com.infected.insta` exactly
