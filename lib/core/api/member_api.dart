import 'api_client.dart';

class MemberApi {
  // ===================== GET MEMBER DETAILS =====================

  static Future<Map<String, dynamic>> getMemberDetails({
    required String token,
    required int memberId,
  }) async {
    return ApiClient.get(
      '/members/$memberId',
      token: token,
    );
  }

  // ===================== UPDATE MEMBER DETAILS =====================

  static Future<Map<String, dynamic>> updateMemberDetails({
    required String token,
    required int memberId,
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String dateOfBirth,
    required String address,
  }) async {
    return ApiClient.put(
      '/members/$memberId',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
      },
      token: token,
    );
  }

  // ===================== CHANGE PASSWORD =====================

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required int memberId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return ApiClient.put(
      '/members/$memberId/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      token: token,
    );
  }

  // ===================== QR TOKEN =====================
  static Future<Map<String, dynamic>> getQrToken({
    required String token,
    required int memberId,
  }) async {
    return ApiClient.post(
      '/members/$memberId/qr-token',
      body: {},
      token: token,
      memberId: memberId,
    );
  }
}
