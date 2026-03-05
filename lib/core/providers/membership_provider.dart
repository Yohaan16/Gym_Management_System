import 'package:flutter/material.dart';
import '../api/membership_api.dart';
import 'auth_provider.dart';

class MembershipProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  Map<String, dynamic>? _membership;
  bool _isLoading = false;
  String? _error;

  MembershipProvider(this.authProvider);

  // Getters
  Map<String, dynamic>? get membership => _membership;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get membership
  Future<bool> getMembership(int memberId) async {
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
      final res = await MembershipApi.getMembership(token: token, memberId: memberId);

      if (res['success'] == true) {
        _membership = res['data'] ?? res;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch membership';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching membership: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Renew membership
  Future<bool> renewMembership({
    required int memberId,
    required String membershipType,
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
      final res = await MembershipApi.renewMembership(
        token: token,
        memberId: memberId,
        membershipType: membershipType,
      );

      if (res['success'] == true) {
        await getMembership(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to renew membership';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error renewing membership: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create membership payment intent
  Future<Map<String, dynamic>?> createMembershipPaymentIntent({
    required int memberId,
    required String membershipType,
    required double amount,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return null;
    }

    try {
      final res = await MembershipApi.createMembershipPaymentIntent(
        token: token,
        memberId: memberId,
        membershipType: membershipType,
        amount: amount,
      );

      if (res['success'] == true) {
        return res['data'];
      } else {
        _error = res['message'] ?? 'Failed to create payment intent';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error creating payment intent: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Confirm membership renewal
  Future<bool> confirmMembershipRenewal({
    required int memberId,
    required String membershipType,
    required String paymentIntentId,
    double? amount,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await MembershipApi.confirmMembershipRenewal(
        token: token,
        memberId: memberId,
        membershipType: membershipType,
        paymentIntentId: paymentIntentId,
        amount: amount,
      );

      if (res['success'] == true) {
        await getMembership(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to confirm renewal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error confirming renewal: ${e.toString()}';
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
