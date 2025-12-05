import 'package:flutter/material.dart';

/// Utility class for common helper methods
class AppUtils {
  AppUtils._(); // Private constructor to prevent instantiation

  /// Show a custom dialog
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? positiveButtonText,
    String? negativeButtonText,
    VoidCallback? onPositive,
    VoidCallback? onNegative,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (negativeButtonText != null)
            TextButton(
              onPressed: onNegative ?? () => Navigator.pop(context),
              child: Text(negativeButtonText),
            ),
          if (positiveButtonText != null)
            TextButton(
              onPressed: () {
                onPositive?.call();
                Navigator.pop(context);
              },
              child: Text(positiveButtonText),
            ),
        ],
      ),
    );
  }

  /// Delay execution
  static Future<void> delay(Duration duration) => Future.delayed(duration);

  /// Check internet connectivity (basic check)
  static Future<bool> hasInternetConnection() async {
    try {
      // Simple check - in production, use connectivity_plus package
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }

  /// Log debug message
  static void logDebug(String message, {String tag = 'DEBUG'}) {
    debugPrint('[$tag] $message');
  }

  /// Log error message
  static void logError(String message, {String tag = 'ERROR'}) {
    debugPrint('[$tag] $message');
  }

  /// Format time duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Calculate BMI
  static double calculateBMI(double weight, double height) {
    // height in meters
    return weight / (height * height);
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get BMI category color
  static Color getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
