import 'api_client.dart';

class TrackingApi {
  // ===================== UPDATE DAILY TRACKING =====================

  static Future<Map<String, dynamic>> updateDailyTracking({
    required String token,
    required int memberId,
    double? caloriesIntake,
    double? caloriesBurnt,
    int? steps,
    double? waterConsumed,
  }) async {
    return ApiClient.post(
      '/tracking/update',
      body: {
        'member_id': memberId,
        'date': DateTime.now().toLocal().toIso8601String().split('T')[0],
        'calories_intake': caloriesIntake,
        'calories_burnt': caloriesBurnt,
        'steps': steps,
        'water_consumed': waterConsumed,
      },
      token: token,
    );
  }

  // ===================== GET TRACKING HISTORY =====================

  static Future<Map<String, dynamic>> getTrackingHistory({
    required String token,
    required int memberId,
    int days = 7,
  }) async {
    final currentDate = DateTime.now().toLocal().toIso8601String().split('T')[0];
    return ApiClient.get(
      '/tracking/history/$memberId?days=$days&currentDate=$currentDate',
      token: token,
    );
  }

  // ===================== GET DAILY GOALS =====================

  static Future<Map<String, dynamic>> getDailyGoals({
    required String token,
    required int memberId,
  }) async {
    return ApiClient.get(
      '/tracking/goals/$memberId',
      token: token,
    );
  }

  // ===================== UPDATE DAILY GOALS =====================

  static Future<Map<String, dynamic>> updateDailyGoals({
    required String token,
    required int memberId,
    double? caloriesIntake,
    double? caloriesBurnt,
    int? steps,
    double? waterConsumed,
  }) async {
    final List<Map<String, dynamic>> goals = [];

    if (caloriesIntake != null) {
      goals.add({
        'member_id': memberId,
        'goal_type': 'calories_intake',
        'target_value': caloriesIntake,
      });
    }

    if (caloriesBurnt != null) {
      goals.add({
        'member_id': memberId,
        'goal_type': 'calories_burnt',
        'target_value': caloriesBurnt,
      });
    }

    if (steps != null) {
      goals.add({
        'member_id': memberId,
        'goal_type': 'steps',
        'target_value': steps.toDouble(),
      });
    }

    if (waterConsumed != null) {
      goals.add({
        'member_id': memberId,
        'goal_type': 'water_consumed',
        'target_value': waterConsumed,
      });
    }

    final List results = [];

    for (final goal in goals) {
      final response = await ApiClient.post(
        '/tracking/goal',
        body: goal,
        token: token,
      );

      if (!response['success']) {
        return response;
      }

      results.add(response['data']);
    }

    return {
      'success': true,
      'data': results,
    };
  }
}
