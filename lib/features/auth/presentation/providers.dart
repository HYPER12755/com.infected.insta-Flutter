import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/features/auth/data/auth_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

/// Auth repository provider
/// 
/// Provides the AuthRepository instance for authentication operations
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state changes provider
/// 
/// This stream provides updates when authentication state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});
