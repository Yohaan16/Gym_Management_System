import 'package:flutter/material.dart';
import '../api/workout_api.dart';
import 'auth_provider.dart';

class WorkoutProgress {
  final String type;
  final double current;
  final double target;

  WorkoutProgress({required this.type, required this.current, required this.target});
}

class WorkoutProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  List<dynamic> _workouts = [];
  List<WorkoutProgress> workoutProgress = [];
  Map<String, dynamic>? _currentWorkoutGoal;
  int _totalWorkouts = 0;
  bool _isLoading = false;
  String? _error;

  WorkoutProvider(this.authProvider);

  // Getters
  List<dynamic> get workouts => _workouts;
  List<WorkoutProgress> get workouts_progress => workoutProgress;
  Map<String, dynamic>? get currentWorkoutGoal => _currentWorkoutGoal;
  int get totalWorkouts => _totalWorkouts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get workouts
  Future<bool> getWorkouts({
    required int memberId,
    required String workoutType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await WorkoutApi.getWorkouts(token, memberId);

      if (res['success'] == true) {
        _workouts = res['data'] ?? [];
        // Also populate workout progress
        final data = res['data'] as List<dynamic>;
        workoutProgress = data.map((e) {
          return WorkoutProgress(
            type: e['goal_type'] ?? 'unknown',
            current: double.tryParse(e['current_value'].toString()) ?? 0.0,
            target: double.tryParse(e['target_value'].toString()) ?? 0.0,
          );
        }).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch workouts';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching workouts: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add workout
  Future<bool> addWorkout({
    required int memberId,
    required String workoutType,
    required int targetSets,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await WorkoutApi.setWorkoutGoal(
        token: token,
        memberId: memberId,
        workoutType: workoutType,
        targetSets: targetSets.toDouble(),
      );

      if (res['success'] == true) {
        await getWorkouts(memberId: memberId, workoutType: workoutType);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to add workout';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error adding workout: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update workout
  Future<bool> updateWorkout({
    required int memberId,
    required String workoutType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await WorkoutApi.incrementWorkout(
        token: token,
        memberId: memberId,
        workoutType: workoutType,
      );

      if (res['success'] == true) {
        await getWorkouts(memberId: memberId, workoutType: workoutType);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to update workout';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating workout: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Increment counter 
  Future<void> incrementCounter(int memberId, String workoutType) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      return;
    }
    await WorkoutApi.incrementWorkout(
      token: token,
      memberId: memberId,
      workoutType: workoutType,
    );
  }

  // Reset workouts
  Future<bool> resetWorkouts(int memberId) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await WorkoutApi.resetWorkouts(
        token: token,
        memberId: memberId,
      );

      if (res['success'] == true) {
        _totalWorkouts = 0;
        _workouts = [];
        workoutProgress = [];
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to reset workouts';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error resetting workouts: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Set workout goal
  Future<bool> setWorkoutGoal({
    required int memberId,
    required int goalCount,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await WorkoutApi.setWorkoutGoal(
        token: token,
        memberId: memberId,
        workoutType: 'general',
        targetSets: goalCount.toDouble(),
      );

      if (res['success'] == true) {
        _currentWorkoutGoal = res['data'];
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to set workout goal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error setting workout goal: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
