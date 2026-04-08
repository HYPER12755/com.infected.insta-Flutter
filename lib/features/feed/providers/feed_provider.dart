import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';

// In production, this would fetch from Firestore
final feedProvider = FutureProvider<List<Post>>((ref) async {
  // Return empty list - posts will be loaded from Firestore via other providers
  return [];
});
