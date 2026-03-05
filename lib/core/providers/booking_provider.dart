import 'package:flutter/material.dart';
import '../api/booking_api.dart';
import 'auth_provider.dart';

class BookingProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  Map<String, dynamic>? _classDetails;
  List<dynamic> _memberBookings = [];
  List<dynamic> _cancelledSlots = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this.authProvider);

  // Getters
  Map<String, dynamic>? get classDetails => _classDetails;
  List<dynamic> get memberBookings => _memberBookings;
  List<dynamic> get cancelledSlots => _cancelledSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get class details
  Future<bool> getClassDetails(int classId) async {
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
      final res = await BookingApi.getClassDetails(token, classId);

      if (res['success'] == true) {
        _classDetails = res['data'] ?? {};
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch class details';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching class details: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Book class
  Future<bool> bookClass({
    required int memberId,
    required int classId,
    required String bookingDate,
    required String bookingTime,
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
      final res = await BookingApi.bookClass(
        token: token,
        memberId: memberId,
        classId: classId,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        paymentIntentId: paymentIntentId,
      );

      if (res['success'] == true) {
        // Refresh bookings
        await getMemberBookings(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to book class';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error booking class: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get member bookings
  Future<bool> getMemberBookings(int memberId) async {
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
      final res = await BookingApi.getMemberBookings(token, memberId);

      if (res['success'] == true) {
        _memberBookings = res['data'] ?? [];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch bookings';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching bookings: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get cancelled slots
  Future<bool> getCancelledSlots() async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await BookingApi.getCancelledSlots(token);

      if (res['success'] == true) {
        _cancelledSlots = res['data'] ?? [];
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch cancelled slots';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching cancelled slots: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Get slot capacity and booking count
  Future<Map<String, dynamic>?> getSlotCapacity({
    required int classId,
    required String date,
    required String timeslot,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return null;
    }

    try {
      final res = await BookingApi.getSlotCapacity(
        token: token,
        classId: classId,
        date: date,
        timeslot: timeslot,
      );

      if (res['data'] != null) {
        final data = res['data'];
        // API returns {capacity, count} directly in data (double wrapped)
        if (data['capacity'] != null && data['count'] != null) {
          return {'capacity': data['capacity'], 'count': data['count']};
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
