/// Centralized URL configuration for the application
///
/// All URLs should be configured here and accessed via AppConfig.
/// This allows for easy configuration across different environments.
library;

class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mrvggotawuxvopjhfagb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_RZHUbEH2iQ_pxpsZrtwg7g_1L0gYHJ5',
  );

  // External Service URLs
  static const String googleLogoUrl = String.fromEnvironment(
    'GOOGLE_LOGO_URL',
    defaultValue:
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_light_color_24dp.png',
  );

  static const String githubLogoUrl = String.fromEnvironment(
    'GITHUB_LOGO_URL',
    defaultValue:
        'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
  );

  // Placeholder Image URLs
  static const String placeholderAvatarUrl = String.fromEnvironment(
    'PLACEHOLDER_AVATAR_URL',
    defaultValue: 'https://via.placeholder.com/150',
  );

  static const String pravatarUrl = String.fromEnvironment(
    'PRAVATAR_URL',
    defaultValue: 'https://i.pravatar.cc/150',
  );

  // URL Validation
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static bool isSupabaseConfigured() {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl != 'YOUR_SUPABASE_URL' &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}
