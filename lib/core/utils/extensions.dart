import 'package:flutter/material.dart';

/// Utility extension methods for common operations
extension StringExtensions on String {
  /// Check if string is empty or only contains whitespace
  bool get isNullOrEmpty => isEmpty || trim().isEmpty;

  /// Capitalize first letter
  String get capitalize => isNullOrEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number
  bool get isValidPhone => RegExp(r'^[0-9]{10,}$').hasMatch(replaceAll(RegExp(r'\D'), ''));
}

/// Utility extension methods for numbers
extension NumExtensions on num {
  /// Convert to percentage string
  String toPercentageString({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Format as currency
  String toCurrencyString({String symbol = '\$'}) {
    return '$symbol${toStringAsFixed(2)}';
  }
}

/// Utility extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Format as 'HH:mm' format
  String get timeString => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Format as 'dd MMM yyyy' format
  String get dateString {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${day.toString().padLeft(2, '0')} ${months[month - 1]} $year';
  }
}

/// Utility extension methods for Lists
extension ListExtensions<T> on List<T> {
  /// Get item at index safely, return null if out of range
  T? safeAt(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// Check if list has duplicates
  bool get hasDuplicates => length != toSet().length;
}

/// Utility extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get device padding (for safe area)
  EdgeInsets get devicePadding => MediaQuery.of(this).padding;

  /// Check if device is in landscape
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if device is in portrait
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;

  /// Show snackbar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
}
