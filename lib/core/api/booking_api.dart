import 'api_client.dart';

class BookingApi {
  // ===================== CREATE BOOKING =====================

  static Future<Map<String, dynamic>> bookClass({
    required String token,
    required int memberId,
    required int classId,
    required String bookingDate,
    required String bookingTime,
    required String paymentIntentId,
  }) async {
    return ApiClient.post(
      '/bookings',
      body: {
        'member_id': memberId,
        'class_id': classId,
        'booking_date': bookingDate,
        'booking_time': bookingTime,
        'paymentIntentId': paymentIntentId,
      },
      token: token,
    );
  }

  // ===================== GET CLASS DETAILS =====================

  static Future<Map<String, dynamic>> getClassDetails(
    String token,
    int classId,
  ) async {
    return ApiClient.get(
      '/bookings/class/$classId',
      token: token,
    );
  }

  // ===================== GET MEMBER BOOKINGS =====================

  static Future<Map<String, dynamic>> getMemberBookings(
    String token,
    int memberId,
  ) async {
    return ApiClient.get(
      '/bookings/member/$memberId',
      token: token,
    );
  }

  // ===================== GET CANCELLED SLOTS =====================

  static Future<Map<String, dynamic>> getCancelledSlots(String token) async {
    return ApiClient.get(
      '/bookings/cancelled-slots',
      token: token,
    );
  }

  // ===================== GET SLOT CAPACITY & COUNT =====================

  static Future<Map<String, dynamic>> getSlotCapacity({
    required String token,
    required int classId,
    required String date,
    required String timeslot,
  }) async {
    final encodedTimeslot = Uri.encodeComponent(timeslot);
    return ApiClient.get(
      '/bookings/slot-capacity/$classId/$date/$encodedTimeslot',
      token: token,
    );
  }
}
