import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/weight_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final _weightCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  List<Map<String, dynamic>> _weights = [];
  Map<String, dynamic>? _goal;

  bool _loading = true;
  bool _settingGoal = false;

  double _minX = 1, _maxX = 7;

  int get _memberId =>
      context.read<AuthProvider>().memberId ?? 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = context.read<WeightProvider>();

    await p.getWeights(_memberId);
    await p.getGoal(_memberId);

    setState(() {
      _weights = List<Map<String, dynamic>>.from(p.weightHistory);
      _goal = p.weightGoal;
      _loading = false;

      if (_weights.isNotEmpty) {
        final len = _weights.length.toDouble();
        _minX = len > 7 ? len - 6 : 1;
        _maxX = len;

        // ensure a non-zero x-range for the chart (avoids divide-by-zero in fl_chart)
        if ((_maxX - _minX) < 1) {
          _maxX = _minX + 1;
        }
      }
    });
  }

  Future<void> _addWeight() async {
    final value = double.tryParse(_weightCtrl.text);
    if (value == null) return;

    await context.read<WeightProvider>().addWeight(
          memberId: _memberId,
          weight: value,
          recordDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );

    _weightCtrl.clear();
    _load();
  }

  Future<void> _setGoal() async {
    final current = double.tryParse(_currentCtrl.text);
    final target = double.tryParse(_targetCtrl.text);
    if (current == null || target == null) return;

    setState(() => _settingGoal = true);

    final p = context.read<WeightProvider>();
    await p.setGoal(
      memberId: _memberId,
      goalType: 'weight_loss',
      targetValue: target,
    );

    await p.clearWeights(_memberId);
    await p.addWeight(
      memberId: _memberId,
      weight: current,
      recordDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    _currentCtrl.clear();
    _targetCtrl.clear();

    setState(() => _settingGoal = false);
    _load();
  }

  List<FlSpot> get _spots {
    _weights.sort((a, b) =>
        DateTime.parse(a['record_date'])
            .compareTo(DateTime.parse(b['record_date'])));

    return _weights.asMap().entries.map((e) {
      return FlSpot(
        (e.key + 1).toDouble(),
        double.parse(e.value['weight'].toString()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final spots = _spots;
    final minY = spots.isEmpty ? 60.0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1.0;
    final maxY = spots.isEmpty ? 80.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1.0;

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _header("Weight Tracking", themeProvider),
                  const SizedBox(height: 20),

                  if (_goal != null) _goalCard(),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        minX: _minX,
                        maxX: _maxX,
                        minY: minY,
                        maxY: maxY,
                        gridData: const FlGridData(show: false),
                        titlesData: _titles(themeProvider),
                        borderData: _border(themeProvider),
                        extraLinesData: _goalLine(),
                        lineBarsData: [_line(spots)],
                        clipData: const FlClipData.horizontal(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _weightInput(themeProvider),

                  const SizedBox(height: 260),
                ],
              ),
            ),

            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: GradientButton(
                label: "Add New Goal",
                onPressed: _showGoalDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _header(String title, ThemeProvider themeProvider) => _gradientBox(
        child: GradientText(title, fontSize: 18, fontWeight: FontWeight.bold),
      );

  Widget _goalCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Goal: ${double.parse(_goal!['target_value'].toString()).toStringAsFixed(1)} kg",
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );

  Widget _weightInput(ThemeProvider themeProvider) {
    return _gradientBox(
      child: TextField(
        controller: _weightCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Enter today's weight (kg)",
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWeight,
          ),
        ),
      ),
    );
  }

  Widget _gradientBox({required Widget child}) => GradientBox(
        padding: const EdgeInsets.all(2),
        innerPadding: const EdgeInsets.all(14),
        child: Center(child: child),
      );

  FlBorderData _border(ThemeProvider themeProvider) {
    return FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(color: themeProvider.getTextColor(isPrimary: false)),
        bottom: BorderSide(color: themeProvider.getTextColor(isPrimary: false)),
      ),
    );
  }

  FlTitlesData _titles(ThemeProvider themeProvider) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (v, _) => Text("${v.toStringAsFixed(1)}kg",
              style: TextStyle(fontSize: 9, color: themeProvider.getTextColor(isPrimary: false))),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
              style: TextStyle(fontSize: 9, color: themeProvider.getTextColor(isPrimary: false))),
        ),
      ),
    );
  }

  ExtraLinesData? _goalLine() {
    if (_goal == null) return null;
    final y = double.parse(_goal!['target_value'].toString());
    return ExtraLinesData(horizontalLines: [
      HorizontalLine(y: y, color: Colors.green, strokeWidth: 2, dashArray: [6, 4]),
    ]);
  }

  LineChartBarData _line(List<FlSpot> spots) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: AppColors.secondaryBlue,
        barWidth: 3,
        belowBarData: BarAreaData(show: true, color: AppColors.secondaryBlue.withOpacity(.1)),
        dotData: const FlDotData(show: true),
      );

  Widget _dialogField(String label, TextEditingController ctrl) => GradientBox(
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

  void _showGoalDialog() {
    final theme = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.getBackgroundColor(),
        title: _gradientBox(
          child: GradientText("Set Weight Goal",
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField("Current Weight", _currentCtrl),
            const SizedBox(height: 8),
            _dialogField("Target Weight", _targetCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text("Cancel")),
          GradientButton(
            onPressed: _setGoal,
            label: "Save",
            isLoading: _settingGoal,
          ),
        ],
      ),
    );
  }
}
