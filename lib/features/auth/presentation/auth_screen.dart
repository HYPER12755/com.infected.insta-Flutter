import 'package:flutter/material.dart';
import 'package:infected_insta/features/auth/presentation/login_page.dart';
import 'package:infected_insta/features/auth/presentation/signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _showSignup
              ? SignupPage(
                  showLoginPage: () => setState(() => _showSignup = false),
                )
              : LoginPage(
                  showSignupPage: () => setState(() => _showSignup = true),
                ),
        ),
      ),
    );
  }
}
