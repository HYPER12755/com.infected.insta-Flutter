/// Externalized follow request mock data
/// Previously hardcoded in lib/features/activity/screens/notification_screens.dart
class MockRequestsData {
  static const List<Map<String, dynamic>> followRequests = [
    {'id': 1, 'username': 'user_request_1', 'time': '2h ago'},
    {'id': 2, 'username': 'user_request_2', 'time': '5h ago'},
    {'id': 3, 'username': 'user_request_3', 'time': '1d ago'},
  ];

  /// Get follow requests list
  static List<Map<String, dynamic>> get followRequestsList => followRequests;

  /// Get request count
  static int get requestCount => followRequests.length;

  /// Get pending requests count text
  static String get pendingCountText => '$requestCount pending requests';
}
