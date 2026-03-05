import 'package:flutter/material.dart';
import '../api/review_api.dart';
import 'auth_provider.dart';

class ReviewProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final List<dynamic> _memberReviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewProvider(this.authProvider);

  // Getters
  List<dynamic> get memberReviews => _memberReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Submit review
  Future<bool> submitReview({
    required int memberId,
    required String reviewTitle,
    required String message,
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
      final res = await ReviewApi.submitReview(
        token: token,
        memberId: memberId,
        reviewTitle: reviewTitle,
        message: message,
      );

      if (res['success'] == true) {
        return true;
      } else {
        _error = res['message'] ?? 'Failed to submit review';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error submitting review: ${e.toString()}';
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
