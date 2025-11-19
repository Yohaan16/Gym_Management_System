import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CaloriesPage extends StatelessWidget {
  const CaloriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gradientColors = [const Color(0xFFFF0057), const Color(0xFF009DFF)];

    return Scaffold(
      backgroundColor: Colors.white,
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
                        color: Colors.white,
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
                          border: const Border(
                            bottom: BorderSide(width: 1),
                            left: BorderSide(width: 1),
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
                                    style: const TextStyle(fontSize: 10),
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
                                  style: const TextStyle(fontSize: 10),
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
                        "Steps",
                        "6320/10000",
                        FontAwesomeIcons.shoePrints,
                        gradientColors,
                      ),
                      _buildStatBox(
                        "Water",
                        "2.4/3L",
                        FontAwesomeIcons.tint,
                        gradientColors,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- TEXTFIELDS ---
                  _buildGradientTextField("Calories Eaten (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField("Calories Burnt (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField("Steps (+)", gradientColors),
                  const SizedBox(height: 12),
                  _buildGradientTextField("Water Consumed (+)", gradientColors),
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
                color: Colors.white,
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
      String label, String value, IconData icon, List<Color> gradientColors) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: gradientColors[1], size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // --- TEXTFIELD WITH GRADIENT BORDER ---
  Widget _buildGradientTextField(String label, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.5),
        ),
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
