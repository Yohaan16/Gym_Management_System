import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/workout_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final String title;
  final String image;

  const WorkoutDetailsPage({
    super.key,
    required this.title,
    required this.image,
  });

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  bool _started = false;
  bool _resting = false;
  bool _completed = false;

  int _exerciseIndex = 0;
  int _setIndex = 0;
  int _restSeconds = 120;

  Timer? _timer;

  int get _memberId =>
      context.read<AuthProvider>().memberId ?? 1;

  final _gradient = const [Color(0xFFFF0057), Color(0xFF009DFF)];

  // Map of exercise name -> lottie animation asset
  final Map<String, String> _exerciseAnimations = {
    "Bicep Curls": "assets/lottie/bicep_curl.json",
    "Tricep Pulldowns": "assets/lottie/tricep_pulldowns.json",
    "Squats": "assets/lottie/squat.json",
    "Leg Press": "assets/lottie/leg_press.json",
    "Chest Flies": "assets/lottie/chest_flies.json",
    "Push Ups": "assets/lottie/push_up.json",
    "Pull Ups": "assets/lottie/pull_up.json",
    "Deadlift": "assets/lottie/deadlift.json",
    "Burpees": "assets/lottie/burpees.json",
    "Plank": "assets/lottie/plank.json",
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------- LOGIC ----------------

  void _toggleWorkout() {
    _timer?.cancel();
    setState(() {
      _started = !_started;
      _completed = false;
      _resting = false;
      _exerciseIndex = 0;
      _setIndex = 0;
    });
  }

  void _markDone(Map<String, dynamic> exercise) {
    context
        .read<WorkoutProvider>()
        .incrementCounter(_memberId, exercise['muscle']);

    _isLastSetAndExercise()
        ? setState(() => _completed = true)
        : _startRest();
  }

  void _skip() {
    _isLastSetAndExercise()
        ? setState(() => _completed = true)
        : _moveNext();
  }

  bool _isLastSetAndExercise() {
    final e = _exercises[_exerciseIndex];
    return _exerciseIndex == _exercises.length - 1 &&
        _setIndex == e['sets'] - 1;
  }

  void _startRest() {
    setState(() {
      _resting = true;
      _restSeconds = 120;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds == 1) {
        t.cancel();
        _resting = false;
        _moveNext();
      }
      setState(() => _restSeconds--);
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _resting = false;
      _restSeconds = 120;
    });
    _moveNext();
  }

  void _moveNext() {
    final e = _exercises[_exerciseIndex];
    if (_setIndex < e['sets'] - 1) {
      setState(() => _setIndex++);
    } else if (_exerciseIndex < _exercises.length - 1) {
      setState(() {
        _exerciseIndex++;
        _setIndex = 0;
      });
    }
  }

  // ---------------- DATA ----------------

  List<Map<String, dynamic>> get _exercises => _workouts[widget.title] ?? [];

  static const Map<String, List<Map<String, dynamic>>> _workouts = {
    "Arm Workout": [
      {"name": "Bicep Curls", "sets": 3, "reps": 15, "muscle": "Biceps"},
      {"name": "Tricep Pulldowns", "sets": 3, "reps": 12, "muscle": "Triceps"},
    ],
    "Upper Body Workout": [
      {"name": "Bicep Curls", "sets": 3, "reps": 15, "muscle": "Biceps"},
      {"name": "Pull Ups", "sets": 3, "reps": 10, "muscle": "Back"},
      {"name": "Chest Flies", "sets": 3, "reps": 10, "muscle": "Chest"},
    ],
    "Legs Workout": [
      {"name": "Squats", "sets": 4, "reps": 12, "muscle": "Legs"},
      {"name": "Leg Press", "sets": 3, "reps": 10, "muscle": "Legs"},
    ],
    "Chest Workout": [
      {"name": "Chest Flies", "sets": 3, "reps": 10, "muscle": "Chest"},
      {"name": "Push Ups", "sets": 3, "reps": 15, "muscle": "Chest"},
    ],
    "Back Workout": [
      {"name": "Pull Ups", "sets": 3, "reps": 10, "muscle": "Back"},
      {"name": "Deadlift", "sets": 3, "reps": 8, "muscle": "Back"},
    ],
    "Full Body Workout": [
      {"name": "Burpees", "sets": 3, "reps": 10, "muscle": "Abs"},
      {"name": "Plank", "sets": 3, "reps": 1, "muscle": "Abs"},
    ],
  };

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(FontAwesomeIcons.chevronLeft, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.getTextColor())),
        backgroundColor: themeProvider.getBackgroundColor(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _banner(),
          const SizedBox(height: 16),
          _startButton(),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_completed) return _completion();
    if (_started) return _resting ? _restCard() : _exerciseCard();
    return _exerciseList();
  }

  Widget _banner() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(widget.image, height: 200, width: double.infinity, fit: BoxFit.cover),
      );

  Widget _startButton() => GradientButton(
        label: _started ? "Stop Workout" : "Start Workout",
        onPressed: _toggleWorkout,
      );

  Widget _exerciseCard() {
    final e = _exercises[_exerciseIndex];
    return _card(
      Column(
        children: [
          // Exercise animation
          SizedBox(
            height: 160,
            child: Lottie.asset(
              _exerciseAnimations[e['name']] ?? "assets/lottie/default.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 8),

          Text(e['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Set ${_setIndex + 1} of ${e['sets']}", style: TextStyle(color: _gradient[0])),
          Text("${e['reps']} reps"),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: GradientButton(label: "Done", onPressed: () => _markDone(e))),
              const SizedBox(width: 12),
              Expanded(child: _outlineButton("Skip", _skip)),
            ],
          )
        ],
      ),
    );
  }

  Widget _restCard() => _card(
        Column(
          children: [
            const Text("Rest Time", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("$_restSeconds s", style: TextStyle(fontSize: 48, color: _gradient[0])),
            const SizedBox(height: 16),
            GradientButton(label: "Skip Rest", onPressed: _skipRest),
          ],
        ),
      );

  Widget _completion() => _card(
        Column(
          children: [
            Icon(Icons.check_circle, size: 80, color: _gradient[0]),
            const SizedBox(height: 16),
            const Text("Workout Complete!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GradientButton(label: "Start Another Workout", onPressed: _toggleWorkout),
          ],
        ),
      );

  Widget _exerciseList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length,
        itemBuilder: (_, i) {
          final e = _exercises[i];
          return _card(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${e['name']} (${e['sets']}×${e['reps']})"),
                const Icon(FontAwesomeIcons.dumbbell, size: 18),
              ],
            ),
          );
        },
      );

  // ---------------- REUSABLE WIDGETS ----------------

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GradientBox(
          padding: const EdgeInsets.all(2),
          innerPadding: const EdgeInsets.all(20),
          child: child,
        ),
      );

  Widget _outlineButton(String text, VoidCallback onTap) => SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _gradient[0]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 50),
          ),
          child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: _gradient[0])),
        ),
      );
}
