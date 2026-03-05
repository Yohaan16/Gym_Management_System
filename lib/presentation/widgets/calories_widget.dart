import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/tracking_provider.dart';
import 'package:gms_mobile/presentation/widgets/stat_box.dart';

class CaloriesWidget extends StatefulWidget {
  final List<Color> gradientColors;

  const CaloriesWidget({super.key, required this.gradientColors});

  @override
  State<CaloriesWidget> createState() => _CaloriesWidgetState();

  // Static method to refresh all instances
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void triggerRefresh() {
    refreshNotifier.value++;
  }
}

class _CaloriesWidgetState extends State<CaloriesWidget> {
  List<Map<String, dynamic>> _trackingHistory = [];
  Map<String, dynamic> _goals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    CaloriesWidget.refreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    CaloriesWidget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
      final memberId = authProvider.memberId ?? 1;

      // Load tracking history
      if (await trackingProvider.getTrackingHistory(memberId)) {
        _trackingHistory = List<Map<String, dynamic>>.from(trackingProvider.trackingHistory);
      }

      // Load goals
      if (await trackingProvider.getDailyGoals(memberId)) {
        _goals = trackingProvider.dailyGoals ?? {};
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Public method to refresh data
  void refreshData() {
    _loadData();
  }

  int _getCurrentValueFromData(String key, Map<String, dynamic> data) {
    final value = data[key];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null) {
        return doubleParsed.toInt();
      }
      final intParsed = int.tryParse(value);
      return intParsed ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Chart
        SizedBox(
          height: 220,
          child: _trackingHistory.isEmpty
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _trackingHistory.length * 60.0,
              child: BarChart(
                BarChartData(
                  barGroups: _trackingHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final intakeValue = _getCurrentValueFromData('calories_intake', data).toDouble();
                    final burntValue = _getCurrentValueFromData('calories_burnt', data).toDouble();
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: intakeValue,
                          color: const Color(0xFF009DFF),
                          width: 20,
                        ),
                        BarChartRodData(
                          toY: burntValue,
                          color: const Color(0xFFFF0057),
                          width: 20,
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }).toList(),
                  // determine maximum y value from data to allow large numbers
                  maxY: (() {
                    double maxVal = 0;
                    for (var entry in _trackingHistory) {
                      final intake = _getCurrentValueFromData('calories_intake', entry).toDouble();
                      final burn = _getCurrentValueFromData('calories_burnt', entry).toDouble();
                      maxVal = maxVal < intake ? intake : maxVal;
                      maxVal = maxVal < burn ? burn : maxVal;
                    }
                    // also factor in the goal values so they always fit
                    final intakeGoal = double.tryParse(_goals['calories_intake']?.toString() ?? '') ?? 0.0;
                    final burnGoal = double.tryParse(_goals['calories_burnt']?.toString() ?? '') ?? 0.0;
                    maxVal = maxVal < intakeGoal ? intakeGoal : maxVal;
                    maxVal = maxVal < burnGoal ? burnGoal : maxVal;
                    return maxVal + 200; // larger buffer
                  })(),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: themeProvider.getTextColor(isPrimary: false), width: 1),
                      left: BorderSide(color: themeProvider.getTextColor(isPrimary: false), width: 1),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (() {
                          final maxY = (() {
                            double m = 0;
                            for (var entry in _trackingHistory) {
                              final intake = _getCurrentValueFromData('calories_intake', entry).toDouble();
                              final burn = _getCurrentValueFromData('calories_burnt', entry).toDouble();
                              m = m < intake ? intake : m;
                              m = m < burn ? burn : m;
                            }
                            // also consider goals when computing ticks
                            final goal1 = _goals['calories_intake'] is num
                                ? (_goals['calories_intake'] as num).toDouble()
                                : double.tryParse(_goals['calories_intake']?.toString() ?? '') ?? 0.0;
                            final goal2 = _goals['calories_burnt'] is num
                                ? (_goals['calories_burnt'] as num).toDouble()
                                : double.tryParse(_goals['calories_burnt']?.toString() ?? '') ?? 0.0;
                            m = m < goal1 ? goal1 : m;
                            m = m < goal2 ? goal2 : m;
                            return m + 100;
                          })();
                          // divide into about 4 segments
                          return (maxY / 4).ceilToDouble();
                        })(),
                        getTitlesWidget: (value, meta) {
                          // show only major ticks
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: themeProvider.getTextColor(isPrimary: false)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _trackingHistory.length) {
                            final dateStr = _trackingHistory[index]['record_date'] as String?;
                            if (dateStr != null) {
                              try {
                                final datePart = dateStr.split('T')[0]; // Remove time if present
                                final parts = datePart.split('-');
                                final month = int.parse(parts[1]);
                                final day = int.parse(parts[2]);
                                return Text(
                                  '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 10, color: themeProvider.getTextColor(isPrimary: false)),
                                );
                              } catch (e) {
                                return Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 10, color: themeProvider.getTextColor(isPrimary: false)),
                                );
                              }
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  extraLinesData: _goalLines(),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Steps and Water Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox(
              "Steps",
              _getStepsValue(),
              FontAwesomeIcons.shoePrints,
            ),
            _buildStatBox(
              "Water",
              _getWaterValue(),
              FontAwesomeIcons.droplet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return StatBox(
      label: label,
      value: value,
      icon: icon,
      gradientColors: widget.gradientColors,
    );
  }

  ExtraLinesData _goalLines() {
    final intakeGoal = _goals['calories_intake'] is num
        ? (_goals['calories_intake'] as num).toDouble()
        : double.tryParse(_goals['calories_intake']?.toString() ?? '') ?? 0.0;
    final burnGoal = _goals['calories_burnt'] is num
        ? (_goals['calories_burnt'] as num).toDouble()
        : double.tryParse(_goals['calories_burnt']?.toString() ?? '') ?? 0.0;

    // debug output to verify values
    debugPrint('Intake goal: $intakeGoal, Burn goal: $burnGoal');

    final lines = <HorizontalLine>[];
    if (intakeGoal > 0) {
      lines.add(HorizontalLine(
          y: intakeGoal,
          color: const Color(0xFF009DFF).withOpacity(0.7), // blue
          strokeWidth: 3,
          dashArray: [8, 6]));
    }
    if (burnGoal > 0) {
      lines.add(HorizontalLine(
          y: burnGoal,
          color: const Color(0xFFFF0057).withOpacity(0.7), // red
          strokeWidth: 3,
          dashArray: [8, 6]));
    }
    return ExtraLinesData(horizontalLines: lines, extraLinesOnTop: true);
  }

  String _getStepsValue() {
    if (_trackingHistory.isEmpty) return "0/${_goals['steps'] ?? 10000}";
    final latest = _trackingHistory.first;
    final steps = _getCurrentValueFromData('steps', latest);
    final goal = _goals['steps'] ?? 10000;
    return "$steps/$goal";
  }

  String _getWaterValue() {
    if (_trackingHistory.isEmpty) return "0L/${_goals['water_consumed'] ?? 3}L";
    final latest = _trackingHistory.first;
    final water = _getCurrentValueFromData('water_consumed', latest);
    final goal = _goals['water_consumed'] ?? 3;
    return "${water}L/${goal}L";
  }
}
