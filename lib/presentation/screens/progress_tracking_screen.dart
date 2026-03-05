import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'weight_page.dart';
import 'calories_page.dart';
import 'total_workouts_page.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  int selectedIndex = 0;

  final List<String> tabs = ["Weight", "Calories", "Total Workouts"];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final pages = [
      const WeightPage(),
      const CaloriesPage(),
      const TotalWorkoutsPage(),
    ];

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Back arrow
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.chevronLeft,
                      color: themeProvider.getTextColor(),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Centered title
                  Expanded(
                    child: Text(
                      "Progress Tracking",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.getTextColor(),
                      ),
                    ),
                  ),

                  // Right spacer to balance layout
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ---------- Tabs ----------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: AppColors.gradientBluePink)
                              : null,
                          color: isSelected ? null : themeProvider.getSurfaceColor(),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: themeProvider.getSurfaceColor()),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ---------- Page Content ----------
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      ),
    );
  }
}
