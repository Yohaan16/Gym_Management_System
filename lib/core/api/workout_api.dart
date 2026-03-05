import 'api_client.dart';

class WorkoutApi {
  // ===================== GET WORKOUTS + GOALS =====================

  static Future<Map<String, dynamic>> getWorkouts(
    String token,
    int memberId,
  ) async {
    return ApiClient.get(
      '/workouts/$memberId',
      token: token,
    );
  }

  // ===================== SET WORKOUT GOAL =====================

  static Future<Map<String, dynamic>> setWorkoutGoal({
    required String token,
    required int memberId,
    required String workoutType,
    required double targetSets,
  }) async {
    return ApiClient.post(
      '/tracking/goal',
      body: {
        'member_id': memberId,
        'goal_type': workoutType,
        'target_value': targetSets,
      },
      token: token,
    );
  }

  // ===================== INCREMENT WORKOUT (ONE SET DONE) =====================

  static Future<Map<String, dynamic>> incrementWorkout({
    required String token,
    required int memberId,
    required String workoutType,
  }) async {
    return ApiClient.post(
      '/workouts/increment',
      body: {
        'member_id': memberId,
        'workout_type': workoutType,
      },
      token: token,
    );
  }

  // ===================== RESET ALL WORKOUT COUNTERS =====================

  static Future<Map<String, dynamic>> resetWorkouts({
    required String token,
    required int memberId,
  }) async {
    return ApiClient.post(
      '/workouts/reset/$memberId',
      body: {},
      token: token,
    );
  }
}
