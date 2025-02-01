import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// Manages the persistence of the app's theme mode (light/dark) using SharedPreferences
class ThemePreferenceManager {
  static const String _themeKey = 'is_dark_mode';

  // Singleton pattern to ensure a single instance of this class
  static final ThemePreferenceManager _instance =
      ThemePreferenceManager._internal();

  factory ThemePreferenceManager() {
    return _instance;
  }

  ThemePreferenceManager._internal();

  // Returns `true` if dark mode is enabled, `false` otherwise
  Future<bool> isDarkMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; //
  }

  // Save the theme mode preference
  Future<void> setDarkMode(bool isDark) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}

// Manages the app's theme state and notifies listeners when the theme changes
class ThemeProvider with ChangeNotifier {
  late bool _isDarkMode;
  final ThemePreferenceManager _preferenceManager = ThemePreferenceManager();

  ThemeProvider() {
    _isDarkMode = false;
    _loadThemePreference();
  }

  // Returns the current theme mode
  bool get isDarkMode => _isDarkMode;

  // Loads the saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    _isDarkMode = await _preferenceManager.isDarkMode();
    notifyListeners();
  }

  // Toggles the theme between light and dark mode and saves the preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _preferenceManager.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
