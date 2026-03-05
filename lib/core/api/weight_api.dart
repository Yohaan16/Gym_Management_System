import 'api_client.dart';

class WeightApi {
  // ===================== ADD WEIGHT ENTRY =====================

  static Future<Map<String, dynamic>> addWeight({
    required String token,
    required int memberId,
    required double weight,
    required String recordDate,
  }) async {
    return ApiClient.post(
      '/weight/weight',
      body: {
        'member_id': memberId,
        'weight': weight,
        'record_date': recordDate,
      },
      token: token,
    );
  }

  // ===================== GET WEIGHT HISTORY =====================

  static Future<Map<String, dynamic>> getWeights(
    String token,
    int memberId,
  ) async {
    return ApiClient.get(
      '/weight/weight/$memberId',
      token: token,

    );
  }

  // ===================== GET LATEST WEIGHT =====================

  static Future<Map<String, dynamic>> getLatestWeight(
    String token,
    int memberId,
  ) async {
    return ApiClient.get(
      '/weight/weight/$memberId/latest',
      token: token,
    );
  }

  // ===================== CLEAR ALL WEIGHTS =====================

  static Future<Map<String, dynamic>> clearWeights(
    String token,
    int memberId,
  ) async {
    return ApiClient.delete(
      '/weight/weight/$memberId',
      token: token,
    );
  }

  // ===================== SET WEIGHT GOAL =====================

  static Future<Map<String, dynamic>> setGoal({
    required String token,
    required int memberId,
    required String goalType,
    required double targetValue,
  }) async {
    return ApiClient.post(
      '/weight/goal',
      body: {
        'member_id': memberId,
        'goal_type': goalType,
        'target_value': targetValue,
      },
      token: token,
    );
  }

  // ===================== GET WEIGHT GOAL =====================

  static Future<Map<String, dynamic>> getGoal(
    String token,
    int memberId,
  ) async {
    return ApiClient.get(
      '/weight/goal/$memberId',
      token: token,
    );
  }
}
