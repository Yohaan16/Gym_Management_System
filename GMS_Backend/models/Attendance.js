const db = require('../config/database');

class AttendanceModel {
  /**
   * Insert attendance
   */
  static async insert({ member_id, jti = null, status = 'IN', scanned_by = null }) {
    const sql = `
      INSERT INTO attendance (member_id, jti, status, scanned_by)
      VALUES (?, ?, ?, ?)
    `;
    const res = await db.query(sql, [member_id, jti, status, scanned_by]);
    return res.insertId || res.insert_id || null;
  }

  /**
   * Get the latest attendance record for a member
   */
  static async getLatestForMember(memberId) {
    const rows = await db.query(
      `SELECT attendance_id, member_id, jti, status, scanned_at, scanned_by
       FROM attendance
       WHERE member_id = ?
       ORDER BY scanned_at DESC
       LIMIT 1`,
      [memberId]
    );
    return rows.length ? rows[0] : null;
  }

  /**
   * Find an attendance row by JTI (used to detect/reply to replay attempts)
   */
  static async getByJti(jti) {
    if (!jti) return null;
    const rows = await db.query(
      `SELECT attendance_id, member_id, jti, status, scanned_at, scanned_by
       FROM attendance
       WHERE jti = ?
       LIMIT 1`,
      [jti]
    );
    return rows.length ? rows[0] : null;
  }

  /**
   * Get currently checked-in members (latest status = 'IN')
   */
  static async getCurrentlyIn() {
    const rows = await db.query(`
      SELECT a.attendance_id, a.member_id, a.status, a.scanned_at,
             m.member_id AS member_id, m.name, m.email, m.phone
      FROM attendance a
      JOIN member m ON a.member_id = m.member_id
      WHERE a.scanned_at = (
        SELECT MAX(a2.scanned_at) FROM attendance a2 WHERE a2.member_id = a.member_id
      )
      AND a.status = 'IN'
      ORDER BY a.scanned_at DESC
    `);
    return rows;
  }
}

module.exports = AttendanceModel;
