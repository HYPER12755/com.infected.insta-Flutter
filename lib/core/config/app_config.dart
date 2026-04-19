/// Centralised app configuration.
/// All URLs / keys loaded from --dart-define at build time,
/// with sensible defaults so the app still runs in debug.
library;

class AppConfig {
  // ── Supabase ───────────────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mrvggotawuxvopjhfagb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_RZHUbEH2iQ_pxpsZrtwg7g_1L0gYHJ5',
  );

  // ── OAuth logos (served by CDN — always available) ─────────────────────────
  static const String googleLogoUrl =
      'https://developers.google.com/identity/images/g-logo.png';

  static const String githubLogoUrl =
      'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png';

  // ── Fallback avatar (UI Avatars — free, reliable, no dead links) ───────────
  // Usage: ${AppConfig.avatarUrl('username')}
  static String avatarUrl(String name) =>
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}'
      '&background=2A2A3E&color=ffffff&size=150&bold=true';

  // ── URL helpers ────────────────────────────────────────────────────────────
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static bool isSupabaseConfigured() =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  // ── App metadata ───────────────────────────────────────────────────────────
  static const String appName    = 'Infected';
  static const String appVersion = '1.0.0';
  static const String appBundleId= 'com.infected.insta';
}
