import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infected_insta/features/auth/presentation/auth_screen.dart';
import 'package:infected_insta/features/auth/presentation/signup_screen.dart';
import 'package:infected_insta/features/home/home_page.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';
import 'package:infected_insta/features/call/screens/video_call_screen.dart';
import 'package:infected_insta/features/call/models/call_model.dart';

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
    // Call routes
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CallScreen(
          calleeId: extra?['calleeId'] as String?,
          calleeName: extra?['calleeName'] as String?,
          calleeAvatar: extra?['calleeAvatar'] as String?,
          callType: extra?['callType'] as CallType?,
        );
      },
    ),
    GoRoute(
      path: '/video-call',
      builder: (context, state) => const VideoCallScreen(),
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    // For now, we'll keep the redirection logic simple.
    // We can add auth state checks here later.
    return null;
  },
);
