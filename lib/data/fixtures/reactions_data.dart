/// Externalized reaction emoji configurations
/// Previously hardcoded in lib/features/feed/screens/post_screens.dart
class ReactionsData {
  static const List<String> reactions = [
    '❤️',
    '😍',
    '😢',
    '😮',
    '😡',
    '🔥',
    '👏',
    '😎',
  ];

  /// Get reactions list
  static List<String> get reactionsList => reactions;

  /// Get reaction count
  static int get reactionCount => reactions.length;
}
