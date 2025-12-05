import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CaloriesBarChart extends StatelessWidget {
  final List<Color> gradientColors;

  const CaloriesBarChart({super.key, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 500,
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
                    color: const Color(0xFF009DFF),
                    width: 8,
                  ),
                  BarChartRodData(
                    toY: 1500 + i * 80,
                    color: const Color(0xFFFF0057),
                    width: 8,
                  ),
                ],
                barsSpace: 4,
              ),
          ],
        ),
      ),
    );
  }
}
