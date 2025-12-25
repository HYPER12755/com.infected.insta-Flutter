import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/auth/presentation/auth_screen.dart';
import 'package:myapp/features/auth/presentation/providers.dart';
import 'package:myapp/features/auth/presentation/signup_screen.dart';
import 'package:myapp/features/home/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authState.asData?.value != null;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/';
      }

      return null;
    },
  );
});
