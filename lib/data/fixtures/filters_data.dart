import 'package:flutter/material.dart';

/// Externalized filter configurations for image editing
/// Previously hardcoded in lib/features/create_post/screens/create_screens.dart
class FiltersData {
  static const List<Map<String, dynamic>> filters = [
    {'name': 'Original', 'color': null},
    {'name': 'Clarendon', 'color': Colors.blueGrey},  // withOpacity(0.3) applied at runtime
    {'name': 'Gingham', 'color': Colors.brown},   // withOpacity(0.2) applied at runtime
    {'name': 'Moon', 'color': Colors.grey},        // withOpacity(0.4) applied at runtime
    {'name': 'Lark', 'color': Colors.orange},    // withOpacity(0.2) applied at runtime
    {'name': 'Reyes', 'color': Colors.pink},    // withOpacity(0.2) applied at runtime
  ];

  /// Get filter color with opacity applied
  static Color? getFilterColor(String filterName) {
    final filter = filters.firstWhere(
      (f) => f['name'] == filterName,
      orElse: () => {'name': 'Original', 'color': null},
    );
    final color = filter['color'] as Color?;
    if (color == null) return null;
    
    // Apply opacity based on filter name
    switch (filterName) {
      case 'Clarendon':
        return color.withValues(alpha: 0.3);
      case 'Gingham':
      case 'Lark':
      case 'Reyes':
        return color.withValues(alpha: 0.2);
      case 'Moon':
        return color.withValues(alpha: 0.4);
      default:
        return null;
    }
  }

  /// Get filter names only
  static List<String> get filterNames => 
      filters.map((f) => f['name'] as String).toList();
}