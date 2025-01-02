// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs);

  ThemeMode get themeMode {
    final String? themeStr = _prefs.getString(_themePreferenceKey);
    switch (themeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String themeStr;
    switch (mode) {
      case ThemeMode.light:
        themeStr = 'light';
        break;
      case ThemeMode.dark:
        themeStr = 'dark';
        break;
      default:
        themeStr = 'system';
    }
    
    await _prefs.setString(_themePreferenceKey, themeStr);
    notifyListeners();
  }
}