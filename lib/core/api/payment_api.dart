import 'api_client.dart';

class PaymentApi {
  // ===================== REGISTRATION PAYMENT =====================

  static Future<Map<String, dynamic>> createRegistrationPaymentIntent({
    required double amount,
    required String applicationId,
    String? token,
  }) async {
    return ApiClient.post(
      '/reg_application/payments/create-payment-intent',
      body: {
        'amount': amount,
        'applicationId': applicationId,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> recordRegistrationPayment({
    required String applicationId,
    required String paymentIntentId,
    required double amount,
    String? token,
  }) async {
    return ApiClient.post(
      '/reg_application/payments/record-payment',
      body: {
        'applicationId': applicationId,
        'paymentIntentId': paymentIntentId,
        'amount': amount,
      },
      token: token,
    );
  }

  // ===================== CLASS BOOKING PAYMENT =====================

  static Future<Map<String, dynamic>> createClassBookingPaymentIntent({
    required String token,
    required double amount,
    required int classId,
    required int memberId,
  }) async {
    return ApiClient.post(
      '/payments/create-class-booking-payment-intent',
      body: {
        'amount': amount,
        'classId': classId,
        'memberId': memberId,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> recordBookingPayment({
    required String token,
    required int memberId,
    required int classId,
    required String paymentIntentId,
    required double amount,
    String paymentMethod = 'Card',
  }) async {
    return ApiClient.post(
      '/payments/record-booking-payment',
      body: {
        'memberId': memberId,
        'classId': classId,
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
      token: token,
    );
  }
}
