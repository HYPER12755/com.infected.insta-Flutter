import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:infected_insta/features/auth/presentation/providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  final VoidCallback showLoginPage;
  const SignupPage({super.key, required this.showLoginPage});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the Terms of Service')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim().toLowerCase(),
        fullName: _fullNameCtrl.text.trim(),
      );
      if (mounted) {
        // Show verification message then go to onboarding
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your email to verify your account!')));
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_friendlyError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('already registered') || e.contains('already exists')) {
      return 'This email is already registered. Try logging in.';
    }
    if (e.contains('weak_password') || e.contains('password')) {
      return 'Password too weak. Use at least 8 characters with letters and numbers.';
    }
    if (e.contains('invalid')) return 'Please enter a valid email address.';
    return 'Sign up failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 36, color: Color(0xFFC039FF)),
        const SizedBox(height: 16),
        Text('Create an account', style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Join Infected and start sharing your world.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 28),

        Form(key: _formKey, child: Column(children: [
          TextFormField(
            controller: _fullNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.length < 3) return 'At least 3 characters';
              if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                return 'Only letters, numbers, . and _';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: FaIcon(_showPassword
                    ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, size: 16),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 8) return 'At least 8 characters';
              return null;
            },
            enabled: !_isLoading,
          ),
        ])),

        const SizedBox(height: 16),
        // Terms checkbox
        Row(children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            activeColor: primary,
          ),
          Expanded(child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'I agree to the ', style: TextStyle(color: Colors.white54)),
            TextSpan(text: 'Terms of Service',
                style: TextStyle(color: primary, fontWeight: FontWeight.w500)),
            const TextSpan(text: ' and ', style: TextStyle(color: Colors.white54)),
            TextSpan(text: 'Privacy Policy',
                style: TextStyle(color: primary, fontWeight: FontWeight.w500)),
          ]))),
        ]),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 24),
        Row(children: const [
          Expanded(child: Divider(color: Colors.white12)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: Divider(color: Colors.white12)),
        ]),
        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _isLoading ? null : () async {
            await ref.read(authRepositoryProvider).signInWithGoogle();
            if (context.mounted) context.go('/home');
          },
          icon: const FaIcon(FontAwesomeIcons.google, size: 16),
          label: const Text('Continue with Google'),
        ),

        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already have an account? ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          GestureDetector(
            onTap: widget.showLoginPage,
            child: Text('Log in', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }
}
