import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider class to manage theme state
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;

  /// Initialize theme from saved preference
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  /// Toggle theme between light and dark
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Set theme to dark
  void setDarkTheme() {
    if (!_isDarkMode) {
      _isDarkMode = true;
      _prefs.setBool('isDarkMode', true);
      notifyListeners();
    }
  }

  /// Set theme to light
  void setLightTheme() {
    if (_isDarkMode) {
      _isDarkMode = false;
      _prefs.setBool('isDarkMode', false);
      notifyListeners();
    }
  }
}
