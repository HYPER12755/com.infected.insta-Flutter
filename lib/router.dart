import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/auth/presentation/auth_screen.dart';
import 'package:myapp/features/auth/presentation/signup_screen.dart';
import 'package:myapp/features/home/home_page.dart';

final router = GoRouter(
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
    // For now, we'll keep the redirection logic simple.
    // We can add auth state checks here later.
    return null;
  },
);
