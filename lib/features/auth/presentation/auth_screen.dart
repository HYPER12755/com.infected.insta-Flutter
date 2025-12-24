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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
              final fadeAnimation = FadeTransition(opacity: animation, child: child);
              return SlideTransition(
                position: offsetAnimation,
                child: fadeAnimation,
              );
            },
            child: _showLoginPage
                ? LoginPage(key: const ValueKey('LoginPage'), showSignupPage: _togglePages)
                : SignupPage(key: const ValueKey('SignupPage'), showLoginPage: _togglePages),
          ),
        ),
      ),
    );
  }
}
