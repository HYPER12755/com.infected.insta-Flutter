# Setup Guide

This guide will help you set up the InstaClone development environment and get the app running on your local machine.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Clone the Repository](#clone-the-repository)
3. [Install Flutter](#install-flutter)
4. [Configure Supabase](#configure-supabase)
5. [Environment Setup](#environment-setup)
6. [Build and Run](#build-and-run)
7. [Optional: Google Sign-In Setup](#optional-google-sign-in-setup)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following installed:

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Flutter SDK** | 3.9.x or higher | [Install Guide](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.x or higher | Included with Flutter |
| **Android Studio** | Latest | For Android development |
| **Xcode** | Latest | For iOS development (macOS only) |
| **Git** | 2.x | Version control |

### System Requirements

- **Operating System**: Windows 10+, macOS 11+, or Linux
- **RAM**: 8GB minimum (16GB recommended)
- **Disk Space**: 2GB for Flutter + project dependencies

---

## Clone the Repository

```bash
# Clone the repository
git clone <repository-url>

# Navigate to project directory
cd myapp
```

---

## Install Flutter

### macOS / Linux

```bash
# Using git (recommended)
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:/path/to/flutter/bin"

# Verify installation
flutter --version
```

### Windows

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to a location (e.g., `C:\flutter`)
3. Add to PATH via System Properties > Environment Variables
4. Run `flutter --version` in a new terminal

### Run Flutter Doctor

```bash
# Verify your Flutter setup
flutter doctor
```

Expected output should show all green checkmarks. Address any issues before proceeding.

---

## Configure Supabase

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Enter project details:
   - **Name**: `instaclone` (or your preferred name)
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your users
4. Click "Create new project"
5. Wait for project to be provisioned (1-2 minutes)

### Step 2: Get API Credentials

1. Go to **Project Settings** (gear icon) → **API**
2. Copy the following values:
   - **Project URL** - e.g., `https://xxxxx.supabase.co`
   - **anon public key** - A long string starting with `eyJ...`

### Step 3: Configure Environment Variables

Update `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // ... rest of config
}
```

Or set environment variables:

```bash
# For Flutter run
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## Environment Setup

### Install Dependencies

```bash
# Get all dependencies
flutter pub get
```

### Configure Android

1. Open `android/app/build.gradle.kts`
2. Ensure minSdkVersion is at least 21:

```kotlin
android {
    defaultConfig {
        minSdk = 21
    }
}
```

3. Add internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
</manifest>
```

### Configure iOS (macOS only)

1. Open `ios/Runner/Info.plist`
2. Add required permissions:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for video calls and posts</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for audio calls</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

---

## Build and Run

### Development Build

```bash
# Run on connected device/emulator
flutter run
```

### Build APK (Android)

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Output location: build/app/outputs/flutter-apk/
```

### Build iOS (macOS)

```bash
# For simulator
flutter build ios --simulator --no-codesign

# For device (requires Apple Developer account)
flutter build ios --release
```

### Hot Reload

During development, use hot reload for fast iterations:

```
# In terminal running flutter run
# Press 'r' to hot reload
# Press 'R' to restart
```

---

## Optional: Google Sign-In Setup

If you want to enable Google OAuth:

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Go to **APIs & Services** → **OAuth consent screen**
4. Configure consent screen (External user type)
5. Add scopes: `email`, `profile`

### Step 2: Create OAuth Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Application type: **Android** or **iOS**
4. For Android:
   - Package name: `com.example.myapp`
   - SHA-1: Get from `keytool` (see below)
5. Copy Client ID

### Get SHA-1 Fingerprint

```bash
# For Android debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Step 3: Configure Supabase

1. In Supabase Dashboard: **Authentication** → **Providers** → **Google**
2. Enable Google provider
3. Add your Client ID and Client Secret
4. Add authorized redirect URI

### Step 4: Update App Code

No additional code needed - Google Sign-In is already integrated!

---

## Troubleshooting

### Common Issues

#### 1. " SUPABASE_URL not configured"

**Solution**: Verify `AppConfig.supabaseUrl` is set correctly in `lib/core/config/app_config.dart`

#### 2. "PlatformException: signed_in_with_fail"

**Solution**: Check your Google OAuth credentials in both Google Cloud Console and Supabase

#### 3. Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

#### 4. Emulator Not Found

```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator-id>
```

#### 5. Port Already in Use

```bash
# Kill process on port 5000 (Supabase local)
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# macOS/Linux
lsof -i :5000
kill -9 <PID>
```

### Getting Help

- **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **GitHub Issues**: Report bugs at project issues page

---

## Next Steps

After getting the app running:

1. [Supabase Setup](SUPABASE.md) - Configure database tables and policies
2. [API Documentation](API.md) - Understand the app's data models
3. [Contributing Guide](CONTRIBUTING.md) - Start contributing!

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous key |
| `GOOGLE_LOGO_URL` | No | Custom Google logo URL |
| `PLACEHOLDER_AVATAR_URL` | No | Default avatar placeholder |
| `PRAVATAR_URL` | No | Random avatar service URL |