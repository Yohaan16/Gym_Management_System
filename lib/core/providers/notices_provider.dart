import 'package:flutter/material.dart';
import '../api/notices_api.dart';
import 'auth_provider.dart';

class NoticesProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  List<Map<String, dynamic>> _notices = [];
  Map<String, dynamic>? _selectedNotice;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get notices => _notices;
  Map<String, dynamic>? get selectedNotice => _selectedNotice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NoticesProvider(this.authProvider);

  // Get all notices
  Future<bool> getAllNotices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check if user is authenticated
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated. Please log in to view notices.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await NoticesApi.getAllNotices(token: token, memberId: authProvider.memberId);

      if (res['success'] == true) {
        // Handle both wrapped and unwrapped responses
        var noticesData = res['data'];
        if (noticesData is Map && noticesData.containsKey('data')) {
          // Response is wrapped: {"data": [...]}
          noticesData = noticesData['data'];
        }
        // noticesData should now be the List
        _notices = List<Map<String, dynamic>>.from(noticesData ?? []);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch notices';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching notices: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear selected notice
  void clearSelectedNotice() {
    _selectedNotice = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}