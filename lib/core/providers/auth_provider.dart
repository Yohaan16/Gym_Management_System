import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userEmail;
  String? _userName;
  int? _memberId;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get memberId => _memberId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _memberId != null && _memberId! > 0;

  AuthProvider() {
    _loadAuthState();
  }

  // Load auth state from SharedPreferences
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userEmail = prefs.getString('userEmail');
      _userName = prefs.getString('userName');
      _memberId = prefs.getInt('memberId');
      notifyListeners();
    } catch (e) {
      // Failed to load auth state
    }
  }

  // Save login data to SharedPreferences
  Future<void> _saveLogin(
    String token,
    int memberId,
    String email,
    String userName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('memberId', memberId);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', userName);
      _token = token;
      _memberId = memberId;
      _userEmail = email;
      _userName = userName;
      notifyListeners();
    } catch (e) {
      // Failed to save login data
    }
  }

  // API Login
  Future<bool> apiLogin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await AuthApi.login(
        email: email,
        password: password,
      );

      if (res['success'] == true) {
        // ApiClient wraps backend response in 'data' field
        final backendResponse = res['data'] ?? {}; 
        final tokenAndData = backendResponse['data'] ?? {}; 
        final token = tokenAndData['token']; 
        final userData = tokenAndData['data'] ?? {}; 

        int memberId = userData['member_id'] ?? userData['id'] ?? 0;
        String userName = userData['name'] ?? '';

        if (token != null && token.isNotEmpty && memberId > 0) {
          await _saveLogin(token, memberId, email, userName);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = 'Invalid token or member ID from server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // backend might return internal JS errors; normalize those to a polite message
        String msg = res['message'] ?? 'Login failed';
        if (msg.contains('Cannot read properties of null') ||
            msg.toLowerCase().contains('password')) {
          msg = 'Invalid Email or Password';
        }
        _error = msg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Cannot read properties of null') ||
          msg.toLowerCase().contains('password')) {
        msg = 'Invalid Email or Password';
      }
      _error = 'Login error: $msg';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // API Register
  Future<Map<String, dynamic>?> apiRegister({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String dateOfBirth,
    required String address,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await AuthApi.register(
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
        password: password,
      );

      if (res['success'] == true) {
        _isLoading = false;
        notifyListeners();
        final wrappedData = res['data'] as Map<String, dynamic>;
        final registrationData = wrappedData['data'] as Map<String, dynamic>;
        return registrationData;
      } else {
        _error = res['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Registration error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('memberId');
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      _token = null;
      _memberId = null;
      _userEmail = null;
      _userName = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      // Failed to logout cleanly
    }
  }
}
