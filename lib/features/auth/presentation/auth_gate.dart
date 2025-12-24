import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/auth/presentation/login_screen.dart';
import 'package:myapp/features/home/presentation/home_screen.dart';
import 'package:myapp/features/auth/presentation/providers.dart';
import 'package:myapp/features/auth/presentation/splash_screen.dart';
import 'package:myapp/features/auth/presentation/email_verification_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    developer.log('Auth State: $authState', name: 'AuthGate');

    return authState.when(
      data: (user) {
        if (user != null) {
          if (user.emailVerified) {
            return const HomeScreen();
          } else {
            return const EmailVerificationScreen();
          }
        }
        return const LoginScreen();
      },
      loading: () => const SplashScreen(),
      error: (error, stackTrace) {
        developer.log('Auth Error', name: 'AuthGate', error: error, stackTrace: stackTrace);
        return Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }
}
