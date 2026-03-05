import 'package:flutter/material.dart';
import '../api/tracking_api.dart';
import 'auth_provider.dart';

class TrackingProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  List<dynamic> _trackingHistory = [];
  Map<String, dynamic>? _dailyGoals;
  bool _isLoading = false;
  String? _error;

  TrackingProvider(this.authProvider);

  // Getters
  List<dynamic> get trackingHistory => _trackingHistory;
  Map<String, dynamic>? get dailyGoals => _dailyGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get tracking history
  Future<bool> getTrackingHistory(int memberId) async {
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
      final res = await TrackingApi.getTrackingHistory(
        token: token,
        memberId: memberId,
      );

      if (res['success'] == true) {
        _trackingHistory = res['data'] ?? [];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch tracking history';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching tracking history: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add daily tracking
  Future<bool> addDailyTracking({
    required int memberId,
    required double caloriesIntake,
    required double caloriesBurnt,
    required int steps,
    required double waterConsumed,
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
      final res = await TrackingApi.updateDailyTracking(
        token: token,
        memberId: memberId,
        caloriesIntake: caloriesIntake,
        caloriesBurnt: caloriesBurnt,
        steps: steps,
        waterConsumed: waterConsumed,
      );

      if (res['success'] == true) {
        await getTrackingHistory(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to add tracking';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error adding tracking: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get daily goals
  Future<bool> getDailyGoals(int memberId) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await TrackingApi.getDailyGoals(
        token: token,
        memberId: memberId,
      );

      if (res['success'] == true) {
        // backend returns an array of goals [{goal_type, target_value}, ...]
        final data = res['data'];
        if (data is List) {
          // convert to map for easier lookup
          _dailyGoals = {};
          for (var g in data) {
            if (g is Map && g.containsKey('goal_type')) {
              _dailyGoals![g['goal_type'].toString()] = g['target_value'];
            }
          }
        } else if (data is Map) {
          // already a map, just assign
          _dailyGoals = Map<String, dynamic>.from(data);
        } else {
          _dailyGoals = {};
        }
        debugPrint('dailyGoals loaded: $_dailyGoals');
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch daily goals';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching daily goals: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update daily goals
  Future<bool> updateDailyGoals({
    required int memberId,
    double? caloriesIntake,
    double? caloriesBurnt,
    int? steps,
    double? waterConsumed,
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
      final res = await TrackingApi.updateDailyGoals(
        token: token,
        memberId: memberId,
        caloriesIntake: caloriesIntake,
        caloriesBurnt: caloriesBurnt,
        steps: steps,
        waterConsumed: waterConsumed,
      );

      if (res['success'] == true) {
        await getDailyGoals(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to update goals';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating goals: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
