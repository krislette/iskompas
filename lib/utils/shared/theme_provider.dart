import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemePreferenceManager {
  static const String _themeKey = 'is_dark_mode';

  // Singleton pattern
  static final ThemePreferenceManager _instance =
      ThemePreferenceManager._internal();

  factory ThemePreferenceManager() {
    return _instance;
  }

  ThemePreferenceManager._internal();

  // Get the current theme mode
  Future<bool> isDarkMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // 
  }

  // Save the theme mode
  Future<void> setDarkMode(bool isDark) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}

// Change Notifier for Theme changes
class ThemeProvider with ChangeNotifier {
  late bool _isDarkMode;
  final ThemePreferenceManager _preferenceManager = ThemePreferenceManager();

  ThemeProvider() {
    _isDarkMode = false;
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    _isDarkMode = await _preferenceManager.isDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _preferenceManager.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
