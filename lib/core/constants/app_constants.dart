/// App-wide constants for text, spacing, sizing, and dimensions
class AppConstants {
  // App Metadata
  static const String appName = 'GMS Mobile';
  static const String appVersion = '1.0.0';

  // Spacing & Padding
  static const double spacingXs = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingBase = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingXl = 24.0;
  static const double spacing2xl = 32.0;
  static const double spacing3xl = 40.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusBase = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 50.0;

  // Font Sizes
  static const double fontXs = 10.0;
  static const double fontSmall = 12.0;
  static const double fontBase = 14.0;
  static const double fontMedium = 16.0;
  static const double fontLarge = 18.0;
  static const double fontXl = 20.0;
  static const double font2xl = 24.0;
  static const double font3xl = 28.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconBase = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXl = 48.0;

  // Animation Durations (in milliseconds)
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Duration autoSwipeDuration = Duration(seconds: 3);

  // Image Paths
  static const String imgGymHeader = 'assets/images/gym_header.jpeg';
  static const String imgBodybuilding = 'assets/images/bodybuilding.jpeg';
  static const String imgYoga = 'assets/images/yoga.jpeg';
  static const String imgPowerlifting = 'assets/images/powerlifting.jpeg';

  // Routes
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeClassBooking = '/class-booking';
  static const String routeProgressTracking = '/progress-tracking';
  static const String routeWorkoutDetails = '/workout-details';
  static const String routeNotifications = '/notifications';
  static const String routeCalories = '/calories';
  static const String routeWeight = '/weight';
  static const String routeMembership = '/membership';
  static const String routeChangePassword = '/change-password';
  static const String routeSendReview = '/send-review';
}
