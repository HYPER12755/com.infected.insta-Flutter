import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/features/auth/data/auth_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream of auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  return supabase.auth.currentUser;
});
