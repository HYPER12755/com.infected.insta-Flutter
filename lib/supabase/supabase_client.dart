import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/core/config/app_config.dart';

/// Supabase client configuration
/// 
/// Uses environment variables via AppConfig:
/// - SUPABASE_URL: Your Supabase project URL (e.g., https://your-project.supabase.co)
/// - SUPABASE_ANON_KEY: Your Supabase anonymous key (found in Project Settings > API)
///
/// Configuration is validated at initialization to ensure valid credentials.
class SupabaseConfig {
  /// Initialize Supabase client with validation
  static Future<void> initialize() async {
    // Validate configuration
    if (!AppConfig.isValidUrl(AppConfig.supabaseUrl)) {
      throw Exception('Invalid SUPABASE_URL. Please provide a valid Supabase project URL.');
    }
    
    if (AppConfig.supabaseAnonKey.isEmpty || 
        AppConfig.supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception('Invalid SUPABASE_ANON_KEY. Please provide a valid anonymous key.');
    }
    
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  /// Get the configured Supabase URL
  static String get url => AppConfig.supabaseUrl;
  
  /// Get the configured Supabase anon key (masked for security)
  static String get anonKey => AppConfig.supabaseAnonKey.isNotEmpty 
      ? '${AppConfig.supabaseAnonKey.substring(0, 8)}...' 
      : 'Not configured';
}

/// Supabase client instance
/// Use this to access Supabase services throughout the app
final supabase = Supabase.instance.client;

/// Auth state changes stream
/// Listen to this stream to react to authentication state changes
Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

/// Current session
Session? get currentSession => supabase.auth.currentSession;

/// Current user
User? get currentUser => currentSession?.user;

/// Check if user is authenticated
bool get isAuthenticated => currentUser != null;
