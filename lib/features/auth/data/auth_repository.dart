import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

/// Auth Repository using Supabase
/// 
/// This repository provides authentication methods using Supabase Auth
class AuthRepository {
  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Current authenticated user, if any
  User? get currentUser => supabase.auth.currentSession?.user;

  /// Current session, if any
  Session? get currentSession => supabase.auth.currentSession;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      },
    );

    // Profile will be created automatically by the trigger
    // No manual insert needed

    return response;
  }

  /// Send email verification
  /// Note: Supabase handles email verification automatically on sign up
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && user.email != null) {
      // Resend is not directly available, but you can use reset password flow
      // Or implement your own email sending through Edge Functions
    }
  }

  /// Check if current user's email is verified
  bool isEmailVerified() {
    final user = currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign in with Google using OAuth
  Future<bool> signInWithGoogle() async {
    final response = await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.infected.insta://auth/callback',
    );
    return response;
  }

  /// Sign in with GitHub using OAuth
  Future<bool> signInWithGitHub() async {
    final response = await supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: 'com.infected.insta://auth/callback',
    );
    return response;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Get user profile by ID from profiles table
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  /// Update user profile in profiles table
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await supabase.from('profiles').update(data).eq('id', userId);
  }
}
