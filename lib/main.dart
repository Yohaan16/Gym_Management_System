import 'package:flutter/material.dart';
import 'package:gms_mobile/presentation/screens/login_screen.dart';
import 'package:gms_mobile/presentation/screens/welcome_screen.dart';
import 'package:gms_mobile/core/themes/app_theme.dart';
import 'package:gms_mobile/presentation/routes/app_routes.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/profile_provider.dart';
import 'package:gms_mobile/core/providers/booking_provider.dart';
import 'package:gms_mobile/core/providers/weight_provider.dart';
import 'package:gms_mobile/core/providers/tracking_provider.dart';
import 'package:gms_mobile/core/providers/payment_provider.dart';
import 'package:gms_mobile/core/providers/membership_provider.dart';
import 'package:gms_mobile/core/providers/review_provider.dart';
import 'package:gms_mobile/core/providers/workout_provider.dart';
import 'package:gms_mobile/core/providers/notices_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe with publishable key
  Stripe.publishableKey = 'pk_test_51Sh2U0LscQhTZSVPBCyxPphg38jZp1OdneW7BCj5UYeylhNoKiAWRSMswreOhhgjo4VrmN9zjlezr0OeDEjCQtTL00ZPy99Rhp';

  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();

  await themeProvider.init();
  // AuthProvider loads its state in constructor

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => BookingProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => WeightProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => TrackingProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => MembershipProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(authProvider)),
        ChangeNotifierProvider(create: (_) => NoticesProvider(authProvider)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          routes: AppRoutes.routes,
          onGenerateRoute: (settings) {
            // Handle unknown routes
            return null;
          },
        );
      },
    );
  }
}
