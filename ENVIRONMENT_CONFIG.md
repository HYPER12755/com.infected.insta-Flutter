# Environment Configuration

This document describes all environment variables required for the application to function properly.

## Required Environment Variables

### Supabase Configuration
| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Your Supabase project URL | `https://your-project.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous key (from Project Settings > API) | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

### External Service URLs
| Variable | Description | Default |
|----------|-------------|---------|
| `GOOGLE_LOGO_URL` | Google logo for OAuth buttons | `https://www.google.com/images/branding/googlelogo/1x/googlelogo_light_color_24dp.png` |
| `GITHUB_LOGO_URL` | GitHub logo for OAuth buttons | `https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png` |

### Placeholder Images
| Variable | Description | Default |
|----------|-------------|---------|
| `PLACEHOLDER_AVATAR_URL` | Default avatar placeholder | `https://via.placeholder.com/150` |
| `PRAVATAR_URL` | Pravatar service URL | `https://i.pravatar.cc/150` |

### Firebase Configuration
| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_PROJECT_ID` | Firebase project ID for real-time features | `your-firebase-project` |

## Setting Environment Variables

### For Development (VS Code)
Add to your `.env` file or VS Code launch configuration:
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

### For Build (Flutter)
```bash
flutter build --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```

### For Android Release
Add to `android/app/build.gradle.kts`:
```kotlin
buildConfigField("String", "SUPABASE_URL", "\"https://your-project.supabase.co\"")
buildConfigField("String", "SUPABASE_ANON_KEY", "\"your-anon-key\"")
```

## Validation

The application validates configuration at startup:
- `AppConfig.isValidUrl()` - Validates URL format
- `AppConfig.isSupabaseConfigured()` - Checks if Supabase credentials are properly set
- `AppConfig.isFirebaseConfigured()` - Checks if Firebase is properly configured

## Migration Status

The following hardcoded URLs have been migrated to use `AppConfig`:

- ✅ Supabase URL and anon key (in `lib/supabase/supabase_client.dart`)
- ✅ Google logo URL (in `lib/features/auth/presentation/login_form.dart` and `signup_form.dart`)
- ✅ GitHub logo URL (in `lib/features/auth/presentation/login_form.dart` and `signup_form.dart`)
- ✅ Placeholder avatar URL (in `lib/features/feed/presentation/feed_screen.dart`)
- ✅ Pravatar URL (in `lib/features/home/home_page.dart`)

## Future Considerations

For production, consider:
1. Using a package like `flutter_dotenv` for environment variable management
2. Implementing a configuration service that loads from a remote config endpoint
3. Adding runtime validation to display configuration errors in the UI