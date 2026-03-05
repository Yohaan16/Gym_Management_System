const db = require('../config/database');

class WeightModel {
  static async addWeight({ member_id, weight, record_date }) {
    // Check if weight entry already exists for this date
    const existing = await db.query(
      'SELECT weight_id FROM weight WHERE member_id = ? AND record_date = ?',
      [member_id, record_date]
    );

    if (existing.length > 0) {
      // Update existing entry
      await db.query(
        'UPDATE weight SET weight = ? WHERE member_id = ? AND record_date = ?',
        [weight, member_id, record_date]
      );
      return existing[0].weight_id;
    } else {
      // Insert new entry
      const result = await db.query(
        'INSERT INTO weight (member_id, weight, record_date) VALUES (?, ?, ?)',
        [member_id, weight, record_date]
      );
      return result.insertId;
    }
  }

  static async getWeights(member_id) {
    const weights = await db.query(
      'SELECT weight_id, weight, record_date FROM weight WHERE member_id = ? ORDER BY record_date ASC',
      [member_id]
    );
    return weights;
  }

  static async getLatestWeight(member_id) {
    const weights = await db.query(
      'SELECT weight, record_date FROM weight WHERE member_id = ? ORDER BY record_date DESC LIMIT 1',
      [member_id]
    );
    return weights.length > 0 ? weights[0] : null;
  }

  static async clearWeights(member_id) {
    await db.query(
      'DELETE FROM weight WHERE member_id = ?',
      [member_id]
    );
  }
}

module.exports = WeightModel;