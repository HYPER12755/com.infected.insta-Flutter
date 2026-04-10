import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/supabase/supabase_client.dart';
import 'package:infected_insta/features/auth/presentation/providers.dart';

/// Auth provider using Supabase
/// 
/// This provider gives access to the current authenticated user
final authProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

/// Auth state changes provider
/// 
/// This stream provides updates when authentication state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Current session provider
final sessionProvider = Provider<Session?>((ref) {
  return supabase.auth.currentSession;
});
