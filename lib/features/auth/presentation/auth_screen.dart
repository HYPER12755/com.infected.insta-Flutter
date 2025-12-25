import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/auth/presentation/login_page.dart';
import 'package:myapp/features/auth/presentation/signup_page.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: LoginPage(
            showSignupPage: () => context.go('/signup'),
          ),
        ),
      ),
    );
  }
}
