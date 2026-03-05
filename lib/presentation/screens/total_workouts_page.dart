import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/workout_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class TotalWorkoutsPage extends StatefulWidget {
  const TotalWorkoutsPage({super.key});

  @override
  State<TotalWorkoutsPage> createState() => _TotalWorkoutsPageState();
}

class _TotalWorkoutsPageState extends State<TotalWorkoutsPage> {
  // Default UI order and values (used as fallback and ordering)
  final Map<String, List<int>> _defaultWorkouts = {
    'Biceps': [5, 15],
    'Triceps': [2, 20],
    'Chest': [10, 20],
    'Back': [8, 15],
    'Abs': [4, 25],
    'Legs': [12, 20],
  };

  // Fixed workout types to display (only workout-related goals)
  final List<String> _workoutTypes = ['Biceps', 'Triceps', 'Chest', 'Back', 'Abs', 'Legs'];

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.toInt() ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    // Fetch workouts on page load
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final int memberId = authProvider.memberId ?? 1;
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    provider.getWorkouts(memberId: memberId, workoutType: 'general');
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = AppColors.gradientBluePink;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final int memberId = authProvider.memberId ?? 1;
    final provider = context.watch<WorkoutProvider>();

    // Build a display map for only workout-related types, preserving order
    final Map<String, List<int>> displayWorkouts = {};
    if (provider.workouts.isNotEmpty) {
      for (var item in provider.workouts) {
        if (item is Map<String, dynamic>) {
          String? type = item['goal_type'];
          if (type != null && _workoutTypes.contains(type)) {
            int current = _parseToInt(item['current_value']);
            int target = _parseToInt(item['target_value']);
            displayWorkouts[type] = [current, target];
          }
        }
      }
    }
    // For types not in data, use default values
    for (final type in _workoutTypes) {
      displayWorkouts.putIfAbsent(type, () => _defaultWorkouts[type]!);
    }

    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GradientBox(
                    padding: const EdgeInsets.all(2),
                    innerPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: GradientText(
                        'Total Workouts',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Workout Progress Bars 
                  for (final entry in displayWorkouts.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _buildWorkoutBar(
                        entry.key,
                        entry.value[0],
                        entry.value[1],
                        gradientColors,
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Clear Counters button placed under the bars 
                  GradientButton(
                    label: "Clear Counters",
                    onPressed: () async {
                      await provider.resetWorkouts(memberId);
                    },
                  ),

                  const SizedBox(height: 40),
                  // Tables: show tracking.goal and workout progress
                  ExpansionTile(
                    title: const Text('Show Tables'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text('Goals (tracking.goal)'),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                if (provider.workouts.isEmpty) {
                                  return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
                                }
                                final data = provider.workouts;
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Goal Type')),
                                      DataColumn(label: Text('Target')),
                                    ],
                                    rows: data.where((e) => e is Map<String, dynamic> && e['goal_type'] != null).map((e) {
                                      return DataRow(cells: [
                                        DataCell(Text(e['goal_type'].toString())),
                                        DataCell(Text(e['target_value'].toString())),
                                      ]);
                                    }).toList(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            const Text('Workouts (joined)'),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Current')),
                                  DataColumn(label: Text('Target')),
                                ],
                                rows: displayWorkouts.entries.map((e) {
                                  return DataRow(cells: [
                                    DataCell(Text(e.key)),
                                    DataCell(Text(e.value[0].toString())),
                                    DataCell(Text(e.value[1].toString())),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  color: themeProvider.getBackgroundColor(),
                      child: Column(
                    children: [
                      GradientButton(
                        label: "Add New Goal",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => _buildAddGoalsDialog(displayWorkouts, memberId, provider),
                          );
                        },
                      ),
                    ],
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with label and count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label  ($current/$total)",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: themeProvider.getTextColor(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: themeProvider.getTextColor(isPrimary: false), size: 22),
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final int memberId = authProvider.memberId ?? 1;
                await context.read<WorkoutProvider>().updateWorkout(memberId: memberId, workoutType: label);
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
                    color: themeProvider.getSurfaceColor(),
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

  // Dialog to add a new goal
  Widget _buildAddGoalsDialog(Map<String, List<int>> displayWorkouts, int memberId,
      WorkoutProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final controllers = <String, TextEditingController>{};
    for (final entry in displayWorkouts.entries) {
      controllers[entry.key] = TextEditingController(text: entry.value[1].toString());
    }

    // helpers mimicking calories page styling
    Widget gradientTitle(String text) => GradientBox(
          padding: const EdgeInsets.all(2),
          innerPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: GradientText(text, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

    Widget dialogField(String label, TextEditingController ctrl) => GradientBox(
          innerPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        );

    return AlertDialog(
      scrollable: true,
      backgroundColor: themeProvider.getBackgroundColor(),
      title: gradientTitle('Set Targets'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in controllers.keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: dialogField(type, controllers[type]!),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GradientButton(
          label: 'Save',
          onPressed: () {
            Navigator.pop(context);

            Future.microtask(() async {
              final futures = <Future>[];
              for (final entry in controllers.entries) {
                final value = int.tryParse(entry.value.text.trim()) ?? 0;
                if (value > 0) {
                  futures.add(provider.addWorkout(
                    memberId: memberId,
                    workoutType: entry.key,
                    targetSets: value,
                  ));
                }
              }

              if (futures.isNotEmpty) {
                await Future.wait(futures);
                await provider.getWorkouts(memberId: memberId, workoutType: 'general');
              }
            });
          },
        ),
      ],
    );
  }
}
