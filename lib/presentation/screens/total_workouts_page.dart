import 'package:flutter/material.dart';

class TotalWorkoutsPage extends StatefulWidget {
  const TotalWorkoutsPage({super.key});

  @override
  State<TotalWorkoutsPage> createState() => _TotalWorkoutsPageState();
}

class _TotalWorkoutsPageState extends State<TotalWorkoutsPage> {
  final Color _pink = const Color(0xFFFF0057);
  final Color _blue = const Color(0xFF009DFF);

  final Map<String, List<int>> _workouts = {
    'Biceps': [5, 15],
    'Triceps': [2, 20],
    'Chest': [10, 20],
    'Back': [8, 15],
    'Abs': [4, 25],
    'Shoulders': [6, 18],
    'Legs': [12, 20],
  };

  @override
  Widget build(BuildContext context) {
    final gradientColors = [_pink, _blue];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                          "Total Workouts",
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
                  const SizedBox(height: 30),

                  // Workout Progress Bars
                  for (final entry in _workouts.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _buildWorkoutBar(
                        entry.key,
                        entry.value[0],
                        entry.value[1],
                        gradientColors,
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Fixed Add Goal button
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildWorkoutBar(
      String label, int current, int total, List<Color> gradient) {
    final progress = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with label and count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label  ($current/$total)",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.grey, size: 22),
              onPressed: () {
                setState(() {
                  if (_workouts[label]![0] < _workouts[label]![1]) {
                    _workouts[label]![0]++;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Full-width progress bar (fixed calculation)
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 18,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
