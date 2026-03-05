const db = require('../config/database');

class StatsModel {
  // Get total number of members
  static async getTotalMembers() {
    const sql = 'SELECT COUNT(*) as total FROM gms_database.member';
    const [rows] = await db.query(sql);
    return rows.total || 0;
  }

  // Get new registrations this month
  static async getNewRegistrationsThisMonth() {
    const sql = `
      SELECT COUNT(*) as total 
      FROM gms_database.registration_application 
      WHERE MONTH(application_date) = MONTH(CURRENT_DATE()) 
      AND YEAR(application_date) = YEAR(CURRENT_DATE())
    `;
    const [rows] = await db.query(sql);
    return rows.total || 0;
  }

  // Get cancelled memberships
  static async getCancelledMemberships() {
    const sql = 'SELECT COUNT(*) as total FROM gms_database.membership WHERE status = \'cancelled\'';
    const [rows] = await db.query(sql);
    return rows.total || 0;
  }

  // Get top class of the month (most bookings)
  static async getTopClassOfMonth() {
    const sql = `
      SELECT c.class_name, COUNT(*) as cnt
      FROM gms_database.booking b
      JOIN gms_database.class c ON b.class_id = c.class_id
      WHERE MONTH(b.booking_date) = MONTH(CURRENT_DATE())
        AND YEAR(b.booking_date) = YEAR(CURRENT_DATE())
      GROUP BY b.class_id
      ORDER BY cnt DESC
      LIMIT 1
    `;
    const [row] = await db.query(sql);
    return (row && row.class_name) ? row.class_name : 'N/A';
  }

  // Get ranked top classes by total bookings (limit results)
  static async getTopClassesBooked(limit = 5) {
    const n = parseInt(limit, 10) || 5;
    const sql = `
      SELECT c.class_id, c.class_name, COUNT(*) as bookings
      FROM gms_database.booking b
      JOIN gms_database.class c ON b.class_id = c.class_id
      GROUP BY b.class_id
      ORDER BY bookings DESC
      LIMIT ${n}
    `;
    const rows = await db.query(sql);
    return Array.isArray(rows) ? rows : [];
  }

  static async getAttendanceSeries(days = 30) {
    const n = parseInt(days, 10) || 30;
    const daysToFetch = Math.max(1, Math.min(365, n));

    const sql = `
      SELECT DATE(scanned_at) as d, COUNT(DISTINCT member_id) as cnt
      FROM attendance
      WHERE scanned_at >= (CURDATE() - INTERVAL ${daysToFetch - 1} DAY)
      GROUP BY d
      ORDER BY d ASC
    `;

    const rows = await db.query(sql);

    const map = {};
    if (Array.isArray(rows)) {
      rows.forEach(r => {
        const key = r.d instanceof Date ? r.d.toISOString().slice(0, 10) : (r.d || r.date);
        map[key] = Number(r.cnt) || 0;
      });
    }

    const series = [];
    const today = new Date();
    for (let i = daysToFetch - 1; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      series.push({ date: key, count: map[key] || 0 });
    }

    return series;
  }

  // Get list of member names
  static async getMembersList() {
    const sql = 'SELECT name FROM gms_database.member ORDER BY name';
    const rows = await db.query(sql);
    return Array.isArray(rows) ? rows.map(r => r.name) : [];
  }

  // Get list of staff names (from staff table)
  static async getStaffList() {
    const sql = 'SELECT name, role FROM gms_database.staff ORDER BY name';
    const rows = await db.query(sql);
    return Array.isArray(rows) ? rows : [];
  }
}

module.exports = StatsModel;