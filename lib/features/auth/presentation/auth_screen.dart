import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infected_insta/features/auth/presentation/login_page.dart';
import 'package:infected_insta/features/auth/presentation/signup_page.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Logo bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFC039FF), Color(0xFF9B59B6)],
                  ).createShader(b),
                  child: const Text('Infected',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 4),
                Text('Premium Social Experience',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ]),
            ),

            // ── Tab selector ──────────────────────────────────────────
            const SizedBox(height: 28),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(children: [
                    _tab('Sign In', !_showSignup),
                    _tab('Sign Up', _showSignup),
                  ]),
                ),
              ),
            ),

            // ── Form ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0), end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _showSignup
                      ? SignupPage(key: const ValueKey('signup'),
                          showLoginPage: () => setState(() => _showSignup = false))
                      : LoginPage(key: const ValueKey('login'),
                          showSignupPage: () => setState(() => _showSignup = true)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showSignup = label == 'Sign Up'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
