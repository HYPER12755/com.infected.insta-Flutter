import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/features/auth/presentation/providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  final VoidCallback showLoginPage;
  const SignupPage({super.key, required this.showLoginPage});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
            fullName: _fullNameController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(FontAwesomeIcons.wandMagicSparkles, size: 40, color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          Text(
            'Create an account',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Enter your details below to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Name', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(hintText: 'John Doe'),
                  validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 20),
                Text('Username', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(hintText: 'john.doe'),
                  validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                ),
                const SizedBox(height: 20),
                Text('Email', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'name@example.com'),
                  validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 20),
                Text('Password', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, size: 18),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Create Account'),
          ),
          const SizedBox(height: 30),

          // Separator
          Row(
            children: [
              const Expanded(child: Divider(thickness: 0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text('OR SIGN UP WITH', style: Theme.of(context).textTheme.bodySmall),
              ),
              const Expanded(child: Divider(thickness: 0.5)),
            ],
          ),
          const SizedBox(height: 30),

          // Social Logins
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authRepositoryProvider).signInWithGoogle(),
                  icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authRepositoryProvider).signInWithGitHub(),
                  icon: const FaIcon(FontAwesomeIcons.github, size: 18),
                  label: const Text('GitHub'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? ", style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: widget.showLoginPage,
                child: Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
