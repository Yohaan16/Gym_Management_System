# GMS Mobile - Code Organization & Structure

## Overview

This document outlines the reorganized structure of the GMS Mobile Flutter application for better code efficiency, maintainability, and scalability while preserving the existing design.

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Centralized color palette
│   │   ├── app_constants.dart    # App-wide constants (spacing, sizes, routes, paths)
│   │   └── constants.dart        # Main constants barrel file
│   ├── themes/
│   │   └── app_theme.dart        # Global theme configuration
│   └── utils/
│       ├── extensions.dart       # Dart/Flutter extension methods
│       ├── app_utils.dart        # Utility helper functions
│       └── utils.dart            # Utils barrel file
├── data/
│   ├── models/
│   │   ├── models.dart           # Data models (User, Membership, Workout, etc.)
│   │   └── base_model.dart       # Base model abstractions
│   └── services/
│       ├── api_service.dart      # API response wrapper & repository patterns
│       └── repository.dart       # Repository implementations
├── presentation/
│   ├── routes/
│   │   └── app_routes.dart       # Centralized routing configuration
│   ├── screens/
│   │   ├── welcome_screen.dart   # Home/Welcome screen
│   │   ├── login_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── class_booking_screen.dart
│   │   ├── progress_tracking_screen.dart
│   │   ├── workout_details.dart
│   │   ├── notifications_screen.dart
│   │   ├── calories_page.dart
│   │   ├── weight_page.dart
│   │   ├── membership_screen.dart
│   │   ├── change_password_screen.dart
│   │   └── send_review_screen.dart
│   └── widgets/
│       ├── stat_box.dart         # Reusable stat box widget
│       ├── info_field.dart       # Reusable info field widget
│       ├── gradient_button.dart  # Reusable gradient button widget
│       ├── custom_app_bar.dart   # Reusable custom app bar
│       ├── gradient_card.dart    # Reusable gradient card widget
│       ├── calories_widget.dart  # Calories bar chart widget
│       └── widgets.dart          # Widgets barrel file
└── main.dart                     # App entry point
```

## Key Improvements

### 1. **Centralized Constants** (`lib/core/constants/`)
- **`app_colors.dart`**: All hardcoded colors are now centralized in one place for easy theming and maintenance
- **`app_constants.dart`**: Spacing, font sizes, border radius, animation durations, image paths, and route names
- **Benefits**: Single source of truth for design values, easy theme changes

### 2. **Reusable Widgets** (`lib/presentation/widgets/`)
- **`StatBox`**: Reusable stat display widget
- **`InfoField`**: Reusable editable/display info field
- **`GradientButton`**: Reusable gradient button with loading state
- **`CustomAppBar`**: Consistent app bar styling
- **`GradientCard`**: Reusable gradient-bordered card
- **Benefits**: Reduced code duplication, consistent UI/UX, easier maintenance

### 3. **Routing System** (`lib/presentation/routes/`)
- **`app_routes.dart`**: Centralized route definitions and navigation helper methods
- Navigation methods: `navigateTo()`, `replaceWith()`, `pop()`, `popAllAndNavigateTo()`
- **Benefits**: Consistent navigation, easier to track app flow, cleaner screens

### 4. **Utility Helpers** (`lib/core/utils/`)
- **`extensions.dart`**: Useful extension methods on String, num, DateTime, List, BuildContext
  - String validations (email, phone, empty check)
  - DateTime formatting and comparisons
  - BuildContext helpers (screen size, snackbar, theme access)
- **`app_utils.dart`**: Common utility functions (dialogs, BMI calculator, logging, duration formatting)
- **Benefits**: Reusable code, cleaner implementations, reduced boilerplate

### 5. **Data Layer** (`lib/data/`)
- **`models/models.dart`**: Type-safe data models (User, Membership, Workout, ClassBooking)
- **`services/api_service.dart`**: Standardized API response wrapper and repository patterns
- **Benefits**: Scalable for API integration, type safety, easier testing

## Usage Examples

### Using Centralized Colors
```dart
import 'package:gms_mobile/core/constants/app_colors.dart';

// Before
const Color _blue = Color(0xFF3A86FF);

// After
Color myColor = AppColors.primaryBlue;
Color withOpacity = AppColors.withOpacity(AppColors.primaryBlue, 0.5);
```

### Using Constants
```dart
import 'package:gms_mobile/core/constants/app_constants.dart';

SizedBox(height: AppConstants.spacingMedium);
BorderRadius.circular(AppConstants.radiusBase);
```

### Using Reusable Widgets
```dart
import 'package:gms_mobile/presentation/widgets/widgets.dart';

// Stat Box
StatBox(
  label: 'Calories',
  value: '1200',
  icon: Icons.local_fire_department,
  gradientColors: AppColors.gradientBluePink,
)

// Gradient Button
GradientButton(
  label: 'Login',
  gradientColors: AppColors.gradientBluePink,
  onPressed: () { /* handle login */ },
)

// Custom App Bar
CustomAppBar(title: 'Profile', showBackButton: true)
```

### Using Extensions
```dart
import 'package:gms_mobile/core/utils/utils.dart';

// String extensions
'user@example.com'.isValidEmail; // true
'1234567890'.isValidPhone; // true
'hello'.capitalize; // 'Hello'

// DateTime extensions
DateTime.now().dateString; // '05 Dec 2025'
DateTime.now().timeString; // '14:30'

// BuildContext extensions
context.showSnackBar('Hello!');
double width = context.screenWidth;
bool isLandscape = context.isLandscape;
```

### Using Navigation
```dart
import 'package:gms_mobile/presentation/routes/app_routes.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

// Navigate to profile
AppRoutes.navigateTo(context, AppConstants.routeProfile);

// Replace current screen with login
AppRoutes.replaceWith(context, AppConstants.routeLogin);

// Pop current screen
AppRoutes.pop(context);
```

## Migration Guide

### For Existing Screens

Replace hardcoded values with constants:

**Before:**
```dart
Container(
  color: const Color(0xFF3A86FF),
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  child: Text('Hello', style: TextStyle(fontSize: 18)),
)
```

**After:**
```dart
import 'package:gms_mobile/core/constants/app_constants.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

Container(
  color: AppColors.primaryBlue,
  width: double.infinity,
  padding: const EdgeInsets.all(AppConstants.spacingMedium),
  child: Text('Hello', style: TextStyle(fontSize: AppConstants.fontLarge)),
)
```

## Best Practices

1. **Always use constants** for colors, spacing, and sizing
2. **Use extensions** for common operations on built-in types
3. **Use navigation helpers** instead of direct Navigator calls
4. **Create reusable widgets** for repeated UI patterns
5. **Keep screens focused** on UI logic, move business logic to services/repositories
6. **Use models** for type-safe data handling

## Future Improvements

- Add state management (GetX, Provider, or Riverpod)
- Implement proper API client with dio/http
- Add local database layer (SQLite/Hive)
- Implement dependency injection
- Add comprehensive error handling
- Add logging and analytics
- Add unit and widget tests

## File Organization Benefits

| Aspect | Before | After |
|--------|--------|-------|
| Color Consistency | Hardcoded in multiple files | Centralized in app_colors.dart |
| Code Reusability | Low, duplicated widgets | High with reusable components |
| Navigation | Direct imports and navigation | Centralized routing system |
| Constants Management | Scattered throughout | Organized in constants folder |
| Scalability | Difficult | Easy to extend |
| Maintenance | Time-consuming | Efficient |

## Contact & Support

For questions or improvements to the structure, refer to the team leads.

---

**Last Updated**: December 5, 2025
**Version**: 1.0
