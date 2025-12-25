import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/auth/presentation/signup_page.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SignupPage(
            showLoginPage: () => context.go('/login'),
          ),
        ),
      ),
    );
  }
}
