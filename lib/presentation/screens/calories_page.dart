import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/tracking_provider.dart';
import 'package:gms_mobile/presentation/widgets/calories_widget.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  final Map<String, TextEditingController> _track = {
    'eat': TextEditingController(),
    'burn': TextEditingController(),
    'steps': TextEditingController(),
    'water': TextEditingController(),
  };

  final Map<String, TextEditingController> _goal = {
    'eat': TextEditingController(),
    'burn': TextEditingController(),
    'steps': TextEditingController(),
    'water': TextEditingController(),
  };

  Map<String, dynamic> _goals = {};

  AuthProvider get _auth => context.read<AuthProvider>();
  TrackingProvider get _tracking => context.read<TrackingProvider>();
  ThemeProvider get _theme => context.read<ThemeProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final memberId = _auth.memberId ?? 1;

    await Future.wait([
      _tracking.getTrackingHistory(memberId),
      _tracking.getDailyGoals(memberId),
    ]);

    if (_tracking.dailyGoals != null) {
      _goals = _tracking.dailyGoals!;
    }

    if (mounted) setState(() {});
  }

  Future<void> _updateTracking() async {
    final success = await _tracking.addDailyTracking(
      memberId: _auth.memberId ?? 1,
      caloriesIntake: _d(_track['eat']) ?? 0.0,
      caloriesBurnt: _d(_track['burn']) ?? 0.0,
      steps: _i(_track['steps']) ?? 0,
      waterConsumed: _d(_track['water']) ?? 0.0,
    );

    success
        ? _onSuccess(_track.values, 'Tracking updated successfully!')
        : _onError(_tracking.error);
  }

  Future<void> _updateGoals() async {
    // parse values from controllers
    final eat = double.tryParse(_goal['eat']!.text);
    final burn = double.tryParse(_goal['burn']!.text);
    final steps = int.tryParse(_goal['steps']!.text);
    final water = double.tryParse(_goal['water']!.text);

    final success = await _tracking.updateDailyGoals(
      memberId: _auth.memberId ?? 1,
      caloriesIntake: eat,
      caloriesBurnt: burn,
      steps: steps,
      waterConsumed: water,
    );

    if (success && mounted) {
      Navigator.pop(context);
      _onSuccess(_goal.values, 'Goals updated successfully!');
    } else {
      _onError(_tracking.error);
    }
  }

  void _showAddGoalDialog() {
    _goal['eat']!.text = _goals['calories_intake']?.toString() ?? '';
    _goal['burn']!.text = _goals['calories_burnt']?.toString() ?? '';
    _goal['steps']!.text = _goals['steps']?.toString() ?? '';
    _goal['water']!.text = _goals['water_consumed']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        backgroundColor: _theme.getBackgroundColor(),
        title: _gradientBox("Set New Goals"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Max Calories Eaten", _goal['eat']!),
            const SizedBox(height: 8),
            _field("Max Calories Burnt", _goal['burn']!),
            const SizedBox(height: 8),
            _field("Max Steps", _goal['steps']!),
            const SizedBox(height: 8),
            _field("Max Water (L)", _goal['water']!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          GradientButton(
            label: "Update Goals",
            onPressed: _updateGoals,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.gradientBluePink;

    return Scaffold(
      backgroundColor: _theme.getBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _gradientBox("Calories Tracking"),
                  const SizedBox(height: 20),
                  CaloriesWidget(gradientColors: gradient),
                  const SizedBox(height: 30),
                  _field("Calories Eaten (+)", _track['eat']!),
                  const SizedBox(height: 10),
                  _field("Calories Burnt (+)", _track['burn']!),
                  const SizedBox(height: 10),
                  _field("Steps (+)", _track['steps']!),
                  const SizedBox(height: 10),
                  _field("Water Consumed (+)", _track['water']!),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: "Update Tracking",
                    onPressed: _updateTracking,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: _theme.getBackgroundColor(),
                child: GradientButton(
                  label: "Add New Goal",
                  onPressed: _showAddGoalDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _field(String label, TextEditingController c) => GradientBox(
        innerPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );

  Widget _gradientBox(String text) => GradientBox(
        // Keep outer padding thin so the gradient stroke remains thin
        padding: const EdgeInsets.all(2),
        // Make inner area wider so the box spans available width
        innerPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: GradientText(text, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  void _onSuccess(Iterable<TextEditingController> ctrls, String msg) async {
    for (final c in ctrls) {
      c.clear();
    }
    await _loadData();
    CaloriesWidget.triggerRefresh();
    _snack(msg);
  }

  void _onError(String? msg) => _snack(msg ?? 'Something went wrong');

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  double? _d(TextEditingController? c) => double.tryParse(c?.text ?? '');
  int? _i(TextEditingController? c) => int.tryParse(c?.text ?? '');

  @override
  void dispose() {
    for (final c in [..._track.values, ..._goal.values]) {
      c.dispose();
    }
    super.dispose();
  }
}
