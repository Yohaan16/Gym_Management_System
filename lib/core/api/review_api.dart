import 'api_client.dart';

class ReviewApi {
  // ===================== SUBMIT REVIEW =====================

  static Future<Map<String, dynamic>> submitReview({
    required String token,
    required int memberId,
    required String reviewTitle,
    required String message,
  }) async {
    return ApiClient.post(
      '/reviews',
      body: {
        'member_id': memberId,
        'review_title': reviewTitle,
        'message': message,
        'review_date': DateTime.now().toIso8601String().split('T')[0],
      },
      token: token,
    );
  }
}
