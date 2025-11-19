import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final Color pink = const Color(0xFFFF0057);
  final Color blue = const Color(0xFF009DFF);
  final Color green = Colors.green;

  final List<FlSpot> weightData = [
    const FlSpot(1, 70),
    const FlSpot(2, 69.5),
    const FlSpot(3, 69),
    const FlSpot(4, 68.5),
    const FlSpot(5, 68.2),
    const FlSpot(6, 68),
  ];

  final TextEditingController _weightController = TextEditingController();
  final double goalWeight = 68;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---- Current Goal ----
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [pink, blue]),
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
                          "Weight Tracking",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [pink, blue],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 0)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Graph ----
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: 6,
                        minY: 67,
                        maxY: 71,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade300, width: 1),
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1, // ensure unique day labels
                              getTitlesWidget: (value, _) {
                                int day = value.toInt();
                                if (day >= 1 && day <= 6) {
                                  return Text("Day $day",
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),

                        // ---- Lines ----
                        extraLinesData: ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: goalWeight,
                            color: green,
                            strokeWidth: 1.5,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.centerRight,
                              labelResolver: (_) => "Goal (68kg)",
                              style: const TextStyle(
                                  color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ]),

                        lineBarsData: [
                          LineChartBarData(
                            spots: weightData,
                            isCurved: true,
                            color: blue,
                            barWidth: 3,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Input Textfield ----
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [pink, blue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter today’s weight (kg)",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add, color: Colors.grey),
                            onPressed: () {
                              if (_weightController.text.isNotEmpty) {
                                print("Added weight: ${_weightController.text}");
                              }
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 280),
                ],
              ),
            ),

            // ---- Add New Goal Button ----
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [pink, blue]),
                ),
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Add New Goal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
