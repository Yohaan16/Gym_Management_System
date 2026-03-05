import 'api_client.dart';

class MembershipApi {
  // ===================== GET CURRENT MEMBERSHIP =====================

  static Future<Map<String, dynamic>> getMembership({
    required String token,
    required int memberId,
  }) async {
    return ApiClient.get(
      '/membership/$memberId',
      token: token,

    );
  }

  // ===================== RENEW MEMBERSHIP (LOGIC ONLY) =====================

  static Future<Map<String, dynamic>> renewMembership({
    required String token,
    required int memberId,
    required String membershipType, // "Normal" or "Advanced"
  }) async {
    return ApiClient.post(
      '/membership/renew',
      body: {
        'member_id': memberId,
        'membership_type': membershipType,
      },
      token: token,
    );
  }

  // ===================== CREATE PAYMENT INTENT =====================

  static Future<Map<String, dynamic>> createMembershipPaymentIntent({
    required String token,
    required int memberId,
    required String membershipType,
    required double amount,
  }) async {
    return ApiClient.post(
      '/membership/create-payment-intent',
      body: {
        'member_id': memberId,
        'membership_type': membershipType,
        'amount': amount,
      },
      token: token,
    );
  }

  // ===================== CONFIRM RENEWAL AFTER PAYMENT =====================

  static Future<Map<String, dynamic>> confirmMembershipRenewal({
    required String token,
    required int memberId,
    required String membershipType,
    String? paymentIntentId,
    double? amount,
  }) async {
    return ApiClient.post(
      '/membership/confirm-renewal',
      body: {
        'member_id': memberId,
        'membership_type': membershipType,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        if (amount != null) 'amount': amount,
      },
      token: token,
    );
  }
}
