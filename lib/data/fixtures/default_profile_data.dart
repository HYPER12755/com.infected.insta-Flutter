/// Externalized default profile data
/// Previously hardcoded in lib/features/profile/application/profile_provider.dart
class DefaultProfileData {
  static const String defaultName = 'Your Name';
  static const String defaultUsername = 'YourUsername';
  static const String defaultBio = 'This is your bio!';

  /// Get default profile values
  static Map<String, String> get defaultProfile => {
    'name': defaultName,
    'username': defaultUsername,
    'bio': defaultBio,
  };
}