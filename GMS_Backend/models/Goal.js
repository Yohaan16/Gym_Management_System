const db = require('../config/database');

class GoalModel {
  static async setGoal({ member_id, goal_type, target_value }) {
    // Check if goal already exists for this member and type
    const existing = await db.query(
      'SELECT goal_id FROM goal WHERE member_id = ? AND goal_type = ?',
      [member_id, goal_type]
    );

    if (existing.length > 0) {
      // Update existing goal
      await db.query(
        'UPDATE goal SET target_value = ? WHERE member_id = ? AND goal_type = ?',
        [target_value, member_id, goal_type]
      );
      return existing[0].goal_id;
    } else {
      // Insert new goal
      const result = await db.query(
        'INSERT INTO goal (member_id, goal_type, target_value) VALUES (?, ?, ?)',
        [member_id, goal_type, target_value]
      );
      return result.insertId;
    }
  }

  static async getGoal(member_id) {
    const goals = await db.query(
      'SELECT goal_id, goal_type, target_value FROM goal WHERE member_id = ?',
      [member_id]
    );
    return goals.length > 0 ? goals[0] : null;
  }

  static async getGoalsByMember(member_id) {
    const goals = await db.query(
      'SELECT goal_id, goal_type, target_value FROM goal WHERE member_id = ?',
      [member_id]
    );
    return goals;
  }

}

module.exports = GoalModel;