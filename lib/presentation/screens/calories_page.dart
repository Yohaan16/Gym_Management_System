import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

class CaloriesPage extends StatelessWidget {
  const CaloriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);
    final gradientColors = [const Color(0xFFFF0057), const Color(0xFF009DFF)];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkSurfaceLight : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Calories Tracking",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: gradientColors,
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BAR CHART ---
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black, width: 1),
                            left: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black, width: 1),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 500, // cleaner spacing
                              getTitlesWidget: (value, meta) {
                                if (value % 500 == 0) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white54 : Colors.black54),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Text(
                                  days[value.toInt() % days.length],
                                  style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white54 : Colors.black54),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        barGroups: [
                          for (int i = 0; i < 7; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: 1200 + i * 100,
                                  color: const Color(0xFF009DFF), // blue = eaten
                                  width: 8,
                                ),
                                BarChartRodData(
                                  toY: 1500 + i * 80,
                                  color: const Color(0xFFFF0057), // pink = burnt
                                  width: 8,
                                ),
                              ],
                              barsSpace: 4,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- STEPS AND WATER BOXES ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(
                        context,
                        "Steps",
                        "6320/10000",
                        FontAwesomeIcons.shoePrints,
                        gradientColors,
                      ),
                      _buildStatBox(
                        context,
                        "Water",
                        "2.4/3L",
                        FontAwesomeIcons.tint,
                        gradientColors,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- TEXTFIELDS ---
                  _buildGradientTextField(context, "Calories Eaten (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField(context, "Calories Burnt (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField(context, "Steps (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField(context, "Water Consumed (+)", gradientColors),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // --- FIXED ADD NEW GOAL BUTTON ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? AppColors.darkBg : Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Add New Goal",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STAT BOX WIDGET ---
  Widget _buildStatBox(
      BuildContext context,
      String label, 
      String value, 
      IconData icon, 
      List<Color> gradientColors) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      width: 150,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurfaceLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: gradientColors[1], size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white54 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // --- TEXTFIELD WITH GRADIENT BORDER ---
  Widget _buildGradientTextField(BuildContext context, String label, List<Color> gradientColors) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurfaceLight : Colors.white,
          borderRadius: BorderRadius.circular(10.5),
        ),
        child: TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
