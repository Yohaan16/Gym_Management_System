import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

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

  /// Get primary text color based on theme
  Color getTextColor({bool isPrimary = true}) {
    if (isPrimary) {
      return _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    } else {
      return _isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF666666);
    }
  }

  /// Get background color based on theme
  Color getBackgroundColor() {
    return _isDarkMode ? AppColors.darkBg : Colors.white;
  }

  /// Get surface color based on theme
  Color getSurfaceColor() {
    return _isDarkMode ? AppColors.darkSurfaceLight : Colors.grey.shade100;
  }

  /// Get icon color based on theme
  Color getIconColor() {
    return _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  }

  /// Get card color based on theme
  Color getCardColor() {
    return _isDarkMode ? AppColors.darkSurfaceLight : Colors.white;
  }
}
