# 🎯 InstaClone - Social Media App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.9.x-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)
![Supabase](https://img.shields.io/badge/Supabase-Enabled-orange?style=flat-square)

A feature-rich social media application built with Flutter and Supabase, featuring real-time messaging, video/audio calls, stories, reels, and a modern Instagram-like experience.

</div>

---

## ✨ Features

### 🔐 Authentication
- Email & password authentication
- Google OAuth integration
- Password reset functionality
- Email verification
- Session management with Supabase Auth

### 📱 Core Social Features
- **Feed** - Scrollable timeline with posts, likes, and comments
- **Stories** - 24-hour ephemeral content with highlights
- **Reels** - Short-form video content
- **Create Post** - Photo/video uploads with filters and editing
- **Search & Explore** - Discover users, trending tags, and content

### 💬 Messaging
- Real-time direct messaging
- Message requests & filtering
- Online presence indicators
- Message delivery status

### 📞 Voice & Video Calls
- One-on-one audio calls
- Video calls with camera toggle
- Call history and missed call notifications
- WebRTC-based peer-to-peer communication

### 🔔 Notifications
- Activity notifications (likes, comments, follows)
- Follow request management
- Customizable notification preferences

### 👤 Profile Management
- Edit profile (bio, avatar, links)
- Archive and saved posts
- Tagged posts
- Story highlights
- Post grid view

### ⚙️ Settings
- Theme customization (light/dark mode)
- Privacy controls
- Account management
- Push notification settings

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.9.x |
| **Language** | Dart |
| **State Management** | Riverpod / Flutter Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Supabase (Auth, Database, Realtime, Storage) |
| **Video Calls** | WebRTC (flutter_webrtc) |
| **HTTP Client** | Supabase Flutter SDK |
| **Code Generation** | Freezed, JSON Serializable |
| **UI Components** | Material Design 3 |

---

## 📋 Requirements

- **Flutter SDK**: 3.9.x or higher
- **Dart SDK**: 3.x or higher
- **Android SDK**: 21 (Android 5.0) or higher
- **iOS**: 12.0 or higher
- **Supabase Project**: Required for backend services

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd myapp
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Create a Supabase project at [supabase.com](https://supabase.com) and configure your environment variables:

```bash
# In launch.json or environment variables
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_anon_key
```

Or configure in `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

### 4. Run the App

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── router.dart               # Navigation configuration
├── core/
│   ├── config/              # App configuration
│   ├── theme/               # Theme and styling
│   └── widgets/             # Shared widgets
├── data/
│   ├── fixtures/           # Mock data for development
│   ├── models/             # Data models
│   ├── realtime/           # Real-time services
│   └── repositories/       # Data repositories
├── features/
│   ├── activity/           # Notifications
│   ├── auth/               # Authentication
│   ├── call/               # Video/Audio calls
│   ├── chat/               # Messaging
│   ├── create_post/        # Post creation
│   ├── feed/               # Main feed
│   ├── home/               # Home screen
│   ├── profile/            # User profile
│   ├── reels/              # Short videos
│   ├── search/             # Search & Explore
│   ├── settings/           # App settings
│   └── stories/            # Stories feature
└── supabase/
    └── supabase_client.dart # Supabase client setup
```

---

## 🔧 Configuration

### Supabase Setup

1. Create a new Supabase project
2. Enable Authentication providers (Email, Google)
3. Create database tables for users, posts, messages, etc.
4. Configure Row Level Security (RLS) policies
5. Set up Storage buckets for media uploads
6. Enable Realtime subscriptions

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key (from API Settings) |
| `GOOGLE_LOGO_URL` | Google logo for OAuth (optional) |
| `PLACEHOLDER_AVATAR_URL` | Default avatar image |

---

## 🎨 Themes

The app supports both light and dark themes with a glass-morphism design aesthetic. Theme preferences are persisted and can be changed in Settings.

---

## 📱 Screenshots

| Home Feed | Profile | Messages | Video Call |
|-----------|---------|----------|------------|
| ![Feed] | ![Profile] | ![Messages] | ![Call] |

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Troubleshooting

### Common Issues

1. **Supabase Connection Failed**
   - Verify your `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct
   - Check that your Supabase project is active
   - Ensure your IP is not blocked in Supabase dashboard

2. **Build Errors**
   - Run `flutter clean` and `flutter pub get`
   - Ensure Flutter and Dart versions are compatible
   - Check for missing platform configurations

3. **Google Sign-In Not Working**
   - Configure OAuth credentials in Google Cloud Console
   - Add your SHA-1 fingerprint to Supabase and Google Console

---

## 📚 Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Setup Guide](docs/SETUP.md)
- [Supabase Configuration](docs/SUPABASE.md)
- [API Reference](docs/API.md)
- [Contribution Guidelines](docs/CONTRIBUTING.md)

---

## 🌟 Star Us

If you find this project useful, please consider giving it a star on GitHub!

---

<div align="center">

Built with ❤️ using Flutter & Supabase

</div>
