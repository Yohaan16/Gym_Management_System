import 'package:flutter/material.dart';
import '../api/weight_api.dart';
import 'auth_provider.dart';

class WeightProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  List<dynamic> _weightHistory = [];
  Map<String, dynamic>? _latestWeight;
  Map<String, dynamic>? _weightGoal;
  bool _isLoading = false;
  String? _error;

  WeightProvider(this.authProvider);

  // Getters
  List<dynamic> get weightHistory => _weightHistory;
  Map<String, dynamic>? get latestWeight => _latestWeight;
  Map<String, dynamic>? get weightGoal => _weightGoal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add weight entry
  Future<bool> addWeight({
    required int memberId,
    required double weight,
    required String recordDate,
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
      final res = await WeightApi.addWeight(
        token: token,
        memberId: memberId,
        weight: weight,
        recordDate: recordDate,
      );

      if (res['success'] == true) {
        // Refresh weight history
        await getWeights(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to add weight';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error adding weight: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get weight history
  Future<bool> getWeights(int memberId) async {
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
      final res = await WeightApi.getWeights(token, memberId);

      if (res['success'] == true) {
        _weightHistory = res['data'] ?? [];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch weight history';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching weight history: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get latest weight
  Future<bool> getLatestWeight(int memberId) async {
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
      final res = await WeightApi.getLatestWeight(token, memberId);

      if (res['success'] == true) {
        _latestWeight = res['data'] ?? {};
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch latest weight';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching latest weight: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear weights
  Future<bool> clearWeights(int memberId) async {
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
      final res = await WeightApi.clearWeights(token, memberId);

      if (res['success'] == true) {
        _weightHistory = [];
        _latestWeight = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to clear weights';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error clearing weights: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Set weight goal
  Future<bool> setGoal({
    required int memberId,
    required String goalType,
    required double targetValue,
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
      final res = await WeightApi.setGoal(
        token: token,
        memberId: memberId,
        goalType: goalType,
        targetValue: targetValue,
      );

      if (res['success'] == true) {
        // Refresh goal
        await getGoal(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to set weight goal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error setting weight goal: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get weight goal
  Future<bool> getGoal(int memberId) async {
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
      final res = await WeightApi.getGoal(token, memberId);

      if (res['success'] == true) {
        _weightGoal = res['data'] ?? {};
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch weight goal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching weight goal: ${e.toString()}';
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
