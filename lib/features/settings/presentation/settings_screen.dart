import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/features/settings/application/settings_provider.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final primary = Theme.of(context).primaryColor;
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(children: [
        // ── Profile card ──
        _ProfileCard(email: user?.email ?? ''),

        _section('Account'),
        _tile(const FaIcon(FontAwesomeIcons.user, size: 17), 'Edit Profile',
            onTap: () => context.push('/profile/edit')),
        _tile(const FaIcon(FontAwesomeIcons.key, size: 17), 'Change Password',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
        _tile(const FaIcon(FontAwesomeIcons.circleInfo, size: 17), 'Personal Information',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen()))),
        _tile(const FaIcon(FontAwesomeIcons.bookmark, size: 17), 'Saved',
            onTap: () => context.push('/saved')),
        _tile(const FaIcon(FontAwesomeIcons.boxArchive, size: 17), 'Archive',
            onTap: () => context.push('/archive')),

        _section('Notifications'),
        _switchTile(const FaIcon(FontAwesomeIcons.bell, size: 17),
            'Push Notifications', settings.notificationsEnabled,
            onChanged: (_) => notifier.toggleNotifications()),

        _section('Privacy'),
        _switchTile(const FaIcon(FontAwesomeIcons.lock, size: 17),
            'Private Account', settings.isPrivate,
            onChanged: (_) => notifier.togglePrivateAccount()),
        _tile(const FaIcon(FontAwesomeIcons.ban, size: 17), 'Blocked Accounts',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()))),
        _tile(const FaIcon(FontAwesomeIcons.userSlash, size: 17), 'Muted Accounts',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Muted accounts — manage from a user profile')))),
        _tile(const FaIcon(FontAwesomeIcons.shield, size: 17), 'Two-Factor Authentication',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable 2FA in Supabase account settings')))),

        _section('Appearance'),
        _switchTile(
          FaIcon(settings.themeMode == ThemeMode.dark
              ? FontAwesomeIcons.moon : FontAwesomeIcons.sun, size: 17),
          settings.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
          settings.themeMode == ThemeMode.dark,
          onChanged: (_) => notifier.toggleTheme(),
        ),

        _section('About'),
        _tile(const FaIcon(FontAwesomeIcons.circleQuestion, size: 17), 'Help & Support',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit infected.app/help')))),
        _tile(const FaIcon(FontAwesomeIcons.fileLines, size: 17), 'Privacy Policy',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('infected.app/privacy')))),
        _tile(const FaIcon(FontAwesomeIcons.fileContract, size: 17), 'Terms of Service',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('infected.app/terms')))),
        _tile(const FaIcon(FontAwesomeIcons.codeBranch, size: 17), 'Version',
            trailing: const Text('1.0.0',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text('Infected'),
              content: const Text('Version 1.0.0\nBuilt with Flutter & Supabase\n\n© 2025 Infected'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ))),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: OutlinedButton(
            onPressed: () => _confirmLogout(context, ref),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
    child: Text(title.toUpperCase(),
        style: const TextStyle(
            color: Colors.white38, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  );

  Widget _tile(Widget icon, String title,
      {required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      leading: icon,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: trailing ?? const FaIcon(FontAwesomeIcons.chevronRight,
          size: 13, color: Colors.white24),
      onTap: onTap,
      minLeadingWidth: 28,
    );
  }

  Widget _switchTile(Widget icon, String title, bool value,
      {required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: icon,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      minLeadingWidth: 28,
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends ConsumerWidget {
  final String email;
  const _ProfileCard({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/profile/edit'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          const CircleAvatar(
            radius: 32, backgroundColor: Color(0xFF2A2A3E),
            child: FaIcon(FontAwesomeIcons.user, color: Colors.white54, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          )),
          const FaIcon(FontAwesomeIcons.chevronRight, size: 14, color: Colors.white24),
        ]),
      ),
    );
  }
}

// ─── Change Password Screen ───────────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await supabase.auth.updateUser(
          UserAttributes(password: _newPwdCtrl.text.trim()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A),
          title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPwdCtrl,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: FaIcon(_showNew ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      size: 16),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'At least 8 characters';
                if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include an uppercase letter';
                if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: FaIcon(_showConfirm ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      size: 16),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              validator: (v) =>
                  v != _newPwdCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final email = supabase.auth.currentUser?.email;
                if (email != null) {
                  await supabase.auth.resetPasswordForEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset link sent to your email')));
                  }
                }
              },
              child: const Text('Forgot current password?',
                  style: TextStyle(color: Colors.white38)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Personal Info Screen ─────────────────────────────────────────────────────
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A),
          title: const Text('Personal Information')),
      body: ListView(children: [
        const SizedBox(height: 16),
        _infoTile('Email', user?.email ?? 'Not set'),
        _infoTile('Phone', user?.phone ?? 'Not set'),
        _infoTile('Account ID', user?.id.substring(0, 8) ?? ''),
        _infoTile('Account Created',
            user?.createdAt != null
                ? DateTime.parse(user!.createdAt).toString().split(' ')[0]
                : 'Unknown'),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your personal information is used to create and manage your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ]),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

// ─── Blocked Accounts Screen ──────────────────────────────────────────────────
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});
  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _isLoading = false); return; }
    try {
      final res = await supabase
          .from('blocks')
          .select('blocked_id, profiles!blocks_blocked_id_fkey(username, avatar_url)')
          .eq('blocker_id', uid);
      if (mounted) {
        setState(() {
          _blocked = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return {
              'id': r['blocked_id'],
              'username': p['username'] ?? 'user',
              'avatar': p['avatar_url'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _unblock(int i) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final id = _blocked[i]['id'];
    setState(() => _blocked.removeAt(i));
    await supabase.from('blocks').delete()
        .match({'blocker_id': uid, 'blocked_id': id});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A),
          title: const Text('Blocked Accounts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? const Center(child: Text('No blocked accounts',
                  style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: _blocked.length,
                  itemBuilder: (_, i) {
                    final u = _blocked[i];
                    final avatar = u['avatar'] as String? ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2A2A3E),
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar) as ImageProvider : null,
                        child: avatar.isEmpty
                            ? Text((u['username'] as String)[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white)) : null,
                      ),
                      title: Text(u['username'] ?? ''),
                      trailing: TextButton(
                        onPressed: () => _unblock(i),
                        child: const Text('Unblock',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }),
    );
  }
}

// ─── Placeholder screen for stubs ────────────────────────────────────────────
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A), title: Text(title)),
    body: Center(child: Text('$title coming soon',
        style: const TextStyle(color: Colors.white38))),
  );
}
