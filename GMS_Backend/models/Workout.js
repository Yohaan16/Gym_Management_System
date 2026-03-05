const db = require('../config/database');

class WorkoutModel {
  static async increment({ member_id, workout_type }) {
    // Insert initial row or increment current_value
    const sql = `INSERT INTO workout (member_id, workout_type, current_value) VALUES (?, ?, 1)
      ON DUPLICATE KEY UPDATE current_value = current_value + 1`;
    const result = await db.query(sql, [member_id, workout_type]);
    return result;
  }

  static async resetForMember(member_id) {
    const sql = 'UPDATE workout SET current_value = 0 WHERE member_id = ?';
    const result = await db.query(sql, [member_id]);
    return result;
  }

  static async getProgressForMember(member_id) {
    // Join goal and workout to return goal_type, target_value, current_value
    const sql = `SELECT g.goal_type, g.target_value, COALESCE(w.current_value, 0) AS current_value
      FROM goal g
      LEFT JOIN workout w ON g.goal_type = w.workout_type AND g.member_id = w.member_id
      WHERE g.member_id = ?`;
    const rows = await db.query(sql, [member_id]);
    return rows;
  }
}

module.exports = WorkoutModel;
