const db = require('../config/database');

class BookingModel {
  static async createBooking({ member_id, class_id, booking_date, booking_time }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Lock the class row
      const [classRows] = await connection.execute('SELECT capacity FROM class WHERE class_id = ? FOR UPDATE', [class_id]);
      if (!classRows || classRows.length === 0) {
        await connection.rollback();
        throw new Error('Class not found');
      }
      const capacity = classRows[0].capacity;

      // Count confirmed bookings for the specific date and timeslot
      const [countRows] = await connection.execute(
        `SELECT COUNT(*) AS count FROM booking
         WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'confirmed'`,
        [class_id, booking_date, booking_time]
      );

      const count = countRows[0].count;

      if (count >= capacity) {
        await connection.rollback();
        throw new Error('Class is fully booked');
      }

      const [result] = await connection.execute(
        `INSERT INTO booking (member_id, class_id, booking_date, booking_time, status)
         VALUES (?, ?, ?, ?, 'confirmed')`,
        [member_id, class_id, booking_date, booking_time]
      );

      await connection.commit();
      return result.insertId;
    } catch (err) {
      try { await connection.rollback(); } catch (e) {}
      throw err;
    } finally {
      try { connection.release(); } catch (e) {}
    }
  }
}

module.exports = BookingModel;
