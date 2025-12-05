import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';

/// Helper class to get theme-aware colors
class ThemeHelper {
  static Color getTextColor(BuildContext context, {bool isPrimary = true}) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    if (isPrimary) {
      return isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
    } else {
      return isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF666666);
    }
  }

  static Color getIconColor(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  }

  static bool isDarkMode(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF999999);
  }
}
