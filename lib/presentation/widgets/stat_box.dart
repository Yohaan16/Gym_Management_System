import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

/// Reusable stat box widget used across the app
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: 150,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: themeProvider.getCardColor(),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium - 2),
          boxShadow: [
            BoxShadow(
              color: themeProvider.getIconColor().withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: gradientColors[1], size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.getTextColor(isPrimary: false),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: themeProvider.getTextColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
