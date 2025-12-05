import 'package:flutter/material.dart';

/// Centralized color palette for the GMS Mobile app
class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF3A86FF);
  static const Color primaryPink = Color(0xFFFF0057);
  static const Color primaryPurple = Color(0xFF8338EC);

  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF009DFF);
  static const Color accentPink = Color(0xFFff0057);

  // Neutral Colors - Light Theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color blackLight = Color(0xFF1A1A1A);
  static const Color blackDark = Colors.black87;

  // Background Colors - Light Theme
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF5F5F5);
  static const Color bgGrey = Color(0xFFF9F9F9);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF121212);        // Scaffold background
  static const Color darkSurface = Color(0xFF1E1E1E);   // Cards/Containers
  static const Color darkSurfaceLight = Color(0xFF2A2A2A); // Input fields/nested elements
  static const Color darkSurfaceLighter = Color(0xFF3A3A3A); // Even lighter for depth

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  // Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE0E0E0);
  static const Color darkTextLight = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF00B7FF);

  // Gradient Colors
  static const List<Color> gradientBluePink = [primaryBlue, primaryPink];
  static const List<Color> gradientPurpleBlue = [primaryPurple, primaryBlue];
  static const List<Color> gradientPinkPurple = [primaryPink, primaryPurple];

  // Utility method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
