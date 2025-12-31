import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/settings/application/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                // Perform the logout action
                Provider.of<SettingsProvider>(context, listen: false).logout();
                // Navigate to the login screen
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              const _SettingsSectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                screen: const PlaceholderScreen(title: 'Personal Information'),
              ),
              _SettingsTile(
                icon: Icons.bookmark_border,
                title: 'Saved',
                screen: const PlaceholderScreen(title: 'Saved'),
              ),
              _SettingsTile(
                icon: Icons.star_border,
                title: 'Close Friends',
                screen: const PlaceholderScreen(title: 'Close Friends'),
              ),
              const _SettingsSectionHeader(title: 'Privacy'),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Private Account',
                trailing: Switch(
                  value: settingsProvider.isPrivate,
                  onChanged: (value) => settingsProvider.togglePrivateAccount(),
                ),
              ),
              _SettingsTile(
                icon: Icons.block,
                title: 'Blocked Accounts',
                screen: const PlaceholderScreen(title: 'Blocked Accounts'),
              ),
              const _SettingsSectionHeader(title: 'Appearance'),
              _SettingsTile(
                icon: Icons.color_lens_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: settingsProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) => settingsProvider.toggleTheme(),
                ),
              ),
              const _SettingsSectionHeader(title: 'About'),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help',
                screen: const PlaceholderScreen(title: 'Help'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                screen: const PlaceholderScreen(title: 'About'),
              ),
              const Divider(),
              ListTile(
                title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                onTap: () => _showLogoutConfirmationDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? screen;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.screen,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
        }
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('This is the $title screen.'),
      ),
    );
  }
}
