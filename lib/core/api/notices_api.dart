import 'api_client.dart';

class NoticesApi {
  // ===================== GET ALL NOTICES =====================
  static Future<Map<String, dynamic>> getAllNotices({
    required String token,
    int? memberId,
  }) async {
    return ApiClient.get(
      '/notices',
      token: token,
      memberId: memberId,
    );
  }
}