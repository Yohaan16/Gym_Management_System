import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final Color pink = const Color(0xFFFF0057);
  final Color blue = const Color(0xFF009DFF);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const WeightPage(),
      const CaloriesPage(),
      const TotalWorkoutsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
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
                    icon: const FaIcon(
                      FontAwesomeIcons.chevronLeft,
                      color: Colors.black87,
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                              ? LinearGradient(colors: [pink, blue])
                              : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
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
