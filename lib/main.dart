import 'package:flutter/material.dart';
import 'package:gms_mobile/presentation/screens/welcome_screen.dart';
import 'package:gms_mobile/core/themes/app_theme.dart';
import 'package:gms_mobile/presentation/routes/app_routes.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
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
