import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/auth/presentation/auth_screen.dart';
import 'package:myapp/features/auth/presentation/providers.dart';
import 'package:myapp/features/home/home_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) => user != null ? const HomePage() : const AuthScreen(),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Center(child: Text(error.toString())),
    );
  }
}
