const Database = require("../config/database");

class DailyTracking {
  /* =======================
     HELPERS
  ======================= */

  static formatDate(date) {
    const d = new Date(date);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  }

  static today(date = null) {
    return date || new Date().toISOString().split("T")[0];
  }

  /* =======================
     INSERT DAILY TRACKING WITH UPDATE ON KEY
  ======================= */

  static async updateDailyTracking(memberId, trackingData) {
    const today = this.today(trackingData.date);

    const query = `
      INSERT INTO daily_tracking
        (member_id, calories_intake, calories_burnt, steps, water_consumed, record_date)
      VALUES (?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        calories_intake = calories_intake + VALUES(calories_intake),
        calories_burnt  = calories_burnt  + VALUES(calories_burnt),
        steps           = steps           + VALUES(steps),
        water_consumed  = water_consumed  + VALUES(water_consumed)
    `;

    await Database.query(query, [
      memberId,
      Number(trackingData.calories_intake) || 0,
      Number(trackingData.calories_burnt) || 0,
      Number(trackingData.steps) || 0,
      Number(trackingData.water_consumed) || 0,
      today
    ]);

    return { message: "Daily tracking saved successfully" };
  }

  /* =======================
     HISTORY
  ======================= */

  static async getTrackingHistory(memberId, days = 7, currentDate = null) {
    const baseDate = this.today(currentDate);

    const query = `
      SELECT *
      FROM daily_tracking
      WHERE member_id = ?
        AND record_date >= DATE_SUB(?, INTERVAL ? DAY)
      ORDER BY record_date DESC
    `;

    const rows = await Database.query(query, [memberId, baseDate, days]);

    return rows.map(row => ({
      ...row,
      record_date: this.formatDate(row.record_date),
    }));
  }
}

module.exports = DailyTracking;
