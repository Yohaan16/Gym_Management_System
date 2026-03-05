import 'package:flutter/material.dart';
import '../api/member_api.dart';
import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  Map<String, dynamic>? _memberProfile;
  bool _isLoading = false;
  String? _error;
  String? _qrToken;

  ProfileProvider(this.authProvider);

  // Getters
  Map<String, dynamic>? get memberProfile => _memberProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get qrToken => _qrToken;

  // Get member profile
  Future<bool> getMemberProfile(int memberId) async {
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
      final res = await MemberApi.getMemberDetails(
        token: token,
        memberId: memberId,
      );

      if (res['success'] == true) {
        _memberProfile = res['data'] ?? res;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to fetch profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error fetching profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update member profile
  Future<bool> updateMemberProfile({
    required int memberId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String gender,
    required String dateOfBirth,
    required String address,
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
      final res = await MemberApi.updateMemberDetails(
        token: token,
        memberId: memberId,
        name: '$firstName $lastName',
        email: email,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
      );

      if (res['success'] == true) {
        await getMemberProfile(memberId);
        return true;
      } else {
        _error = res['message'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required int memberId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (newPassword != confirmPassword) {
      _error = 'Passwords do not match';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await MemberApi.changePassword(
        token: token,
        memberId: memberId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (res['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error changing password: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get QR token
  Future<bool> getQrToken(int memberId) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final res = await MemberApi.getQrToken(
        token: token,
        memberId: memberId,
      );

      if (res['success'] == true) {
        _qrToken = res['data']?['token'] ?? res['token'];
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Failed to get QR token';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error getting QR token: ${e.toString()}';
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
