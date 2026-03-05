const db = require('../config/database');

(async () => {
  try {
    await db.initialize();
    const rows = await db.query(
      `SELECT COUNT(*) AS count FROM booking WHERE class_id = ? AND DATE(booking_date) = ? AND booking_time = ? AND status = 'confirmed'`,
      [2, '2026-02-02', '18:00 - 19:30']
    );
    console.log('Count result:', rows[0]);

    const classRow = await db.query('SELECT capacity FROM class WHERE class_id = ?', [2]);
    console.log('Class capacity:', classRow[0]);
    await db.close();
  } catch (e) {
    console.error('Error:', e);
  }
})();