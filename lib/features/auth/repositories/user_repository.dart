import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../supabase/supabase_client.dart';
import '../models/user.dart';

final userRepositoryProvider = Provider(
  (ref) => UserRepository(),
);

class UserRepository {
  /// Create a new user profile
  Future<void> createUser(User user) async {
    final data = user.toJson();
    data['id'] = user.id;
    data['created_at'] = DateTime.now().toIso8601String();
    
    await supabase.from('users').insert(data);
  }

  /// Get a user by ID
  Future<User?> getUser(String userId) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return User.fromMap(response, response['id'] as String);
  }

  /// Update user profile
  Future<void> updateUser(User user) async {
    final data = user.toJson();
    await supabase.from('users').update(data).eq('id', user.id);
  }

  /// Stream user data for real-time updates
  Stream<User?> userStream(String userId) {
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((maps) {
          if (maps.isEmpty) return null;
          final data = maps.first;
          return User.fromMap(data, data['id'] as String);
        });
  }
}
