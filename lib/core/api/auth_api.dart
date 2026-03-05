import 'api_client.dart';

class AuthApi {
  // ===================== REGISTER =====================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String dateOfBirth,
    required String address,
    required String password,
  }) async {
    return ApiClient.post(
      '/reg_application/registration',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'password': password,
      },
    );
  }

  // ===================== LOGIN =====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return ApiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
  }
}
