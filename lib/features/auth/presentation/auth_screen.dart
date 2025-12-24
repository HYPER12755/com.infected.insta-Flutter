import 'package:flutter/material.dart';
import 'package:myapp/features/auth/presentation/login_page.dart';
import 'package:myapp/features/auth/presentation/signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLoginPage = true;

  void _togglePages() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _showLoginPage
              ? LoginPage(showSignupPage: _togglePages)
              : SignupPage(showLoginPage: _togglePages),
        ),
      ),
    );
  }
}
