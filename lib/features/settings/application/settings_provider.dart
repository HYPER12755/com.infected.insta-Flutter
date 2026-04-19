import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool isPrivate;
  final bool notificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.isPrivate = false,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({ThemeMode? themeMode, bool? isPrivate, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isPrivate: isPrivate ?? this.isPrivate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void togglePrivateAccount() {
    state = state.copyWith(isPrivate: !state.isPrivate);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());

// Legacy ChangeNotifier kept for compatibility (used by main.dart themeMode)
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }
}
