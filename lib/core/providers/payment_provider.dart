import 'package:flutter/material.dart';
import '../api/payment_api.dart';
import 'auth_provider.dart';

class PaymentProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final List<dynamic> _payments = [];
  Map<String, dynamic>? _latestPayment;
  bool _isLoading = false;
  String? _error;

  PaymentProvider(this.authProvider);

  // Getters
  List<dynamic> get payments => _payments;
  Map<String, dynamic>? get latestPayment => _latestPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create payment intent for registration (applicants)
  Future<Map<String, dynamic>?> createRegistrationPaymentIntent({
    required double amount,
    required String applicationId,
  }) async {
    // Applicants don't have a token yet, so we don't pass one
    try {
      final res = await PaymentApi.createRegistrationPaymentIntent(
        amount: amount,
        applicationId: applicationId,
      );

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null && data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        } else if (data != null && data['clientSecret'] != null) {
          return data; // Already unwrapped
        }
        return data;
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

  Future<bool> recordRegistrationPayment({
    required String applicationId,
    required String paymentIntentId,
    required double amount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await PaymentApi.recordRegistrationPayment(
        applicationId: applicationId,
        paymentIntentId: paymentIntentId,
        amount: amount,
      );

      if (res['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to record payment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error recording payment: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create booking payment intent
  Future<Map<String, dynamic>?> createClassBookingPaymentIntent({
    required int memberId,
    required int classId,
    required double amount,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return null;
    }

    try {
      final res = await PaymentApi.createClassBookingPaymentIntent(
        token: token,
        amount: amount,
        classId: classId,
        memberId: memberId,
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

  // Record booking payment
  Future<bool> recordBookingPayment({
    required int memberId,
    required int classId,
    required double amount,
    required String paymentIntentId,
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
      final res = await PaymentApi.recordBookingPayment(
        token: token,
        memberId: memberId,
        classId: classId,
        amount: amount,
        paymentIntentId: paymentIntentId,
      );

      if (res['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to record payment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error recording payment: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
