import 'package:flutter/material.dart';
import 'package:gms_mobile/presentation/screens/welcome_screen.dart';
import 'package:gms_mobile/presentation/screens/login_screen.dart';
import 'package:gms_mobile/presentation/screens/profile_screen.dart';
import 'package:gms_mobile/presentation/screens/settings_screen.dart';
import 'package:gms_mobile/presentation/screens/class_booking_screen.dart';
import 'package:gms_mobile/presentation/screens/progress_tracking_screen.dart';
import 'package:gms_mobile/presentation/screens/notifications_screen.dart';
import 'package:gms_mobile/presentation/screens/calories_page.dart';
import 'package:gms_mobile/presentation/screens/weight_page.dart';
import 'package:gms_mobile/presentation/screens/membership_screen.dart';
import 'package:gms_mobile/presentation/screens/change_password_screen.dart';
import 'package:gms_mobile/presentation/screens/send_review_screen.dart';
import 'package:gms_mobile/presentation/screens/workout_details.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

/// Central routing configuration for the app
class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    AppConstants.routeHome: (context) => const HomeScreen(),
    AppConstants.routeLogin: (context) => const LoginScreen(),
    AppConstants.routeProfile: (context) => const ProfileScreen(),
    AppConstants.routeSettings: (context) => const SettingsScreen(),
    AppConstants.routeClassBooking: (context) => const ClassBookingScreen(),
    AppConstants.routeProgressTracking: (context) => const ProgressTrackingScreen(),
    AppConstants.routeNotifications: (context) => const NotificationsScreen(),
    AppConstants.routeCalories: (context) => const CaloriesPage(),
    AppConstants.routeWeight: (context) => const WeightPage(),
    AppConstants.routeMembership: (context) => const MembershipScreen(),
    AppConstants.routeChangePassword: (context) => const ChangePasswordScreen(),
    AppConstants.routeSendReview: (context) => const SendReviewScreen(),
    AppConstants.routeWorkoutDetails: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return WorkoutDetailsPage(
        title: args['title'] as String,
        image: args['image'] as String,
      );
    },
  };

  /// Navigate to a named route with optional arguments
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Replace current route with a new one
  static Future<dynamic> replaceWith(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Pop all routes and navigate to a new one
  static Future<dynamic> popAllAndNavigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
