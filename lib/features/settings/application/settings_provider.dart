import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsProvider with ChangeNotifier {
  bool _isPrivate = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isPrivate => _isPrivate;
  ThemeMode get themeMode => _themeMode;

  void togglePrivateAccount() {
    _isPrivate = !_isPrivate;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
