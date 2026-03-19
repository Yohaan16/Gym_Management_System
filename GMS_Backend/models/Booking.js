const db = require('../config/database');

class BookingModel {

  // ===================== CREATE BOOKING =====================

  static async createBooking({ member_id, class_id, booking_date, booking_time }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [classRows] = await connection.execute(
        'SELECT capacity FROM class WHERE class_id = ? FOR UPDATE',
        [class_id]
      );
      if (!classRows || classRows.length === 0) {
        await connection.rollback();
        throw new Error('Class not found');
      }
      const capacity = classRows[0].capacity;

      const [countRows] = await connection.execute(
        `SELECT COUNT(*) AS count FROM booking
         WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'Confirmed'`,
        [class_id, booking_date, booking_time]
      );

      if (countRows[0].count >= capacity) {
        await connection.rollback();
        throw new Error('Class is fully booked');
      }

      const [result] = await connection.execute(
        `INSERT INTO booking (member_id, class_id, booking_date, booking_time, status)
         VALUES (?, ?, ?, ?, 'Confirmed')`,
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

  // ===================== GET BOOKING BY ID =====================

  static async getBookingById(bookingId, memberId) {
    const rows = await db.query(
      `SELECT booking_id, member_id, class_id, booking_date, booking_time, status
       FROM booking WHERE booking_id = ? AND member_id = ?`,
      [bookingId, memberId]
    );
    return rows[0] ?? null;
  }

  // ===================== GET MEMBER BOOKINGS =====================

  static async getMemberBookings(memberId) {
    return db.query(
      `SELECT booking_id, class_id, booking_date, booking_time, status
       FROM booking
       WHERE member_id = ? AND LOWER(status) = 'confirmed'`,
      [memberId]
    );
  }

  // ===================== GET ALL BOOKINGS =====================

  static async getAllBookings() {
    return db.query(`
      SELECT b.booking_id, b.class_id, b.booking_date, b.booking_time, b.status,
             m.member_id, m.name, m.email, m.phone, c.class_name
      FROM booking b
      JOIN member m ON b.member_id = m.member_id
      JOIN class c ON b.class_id = c.class_id
      ORDER BY b.booking_date DESC, b.booking_time ASC
    `);
  }

  // ===================== GET CLASS DETAILS =====================

  static async getClassDetails(classId) {
    const rows = await db.query(
      'SELECT class_id, class_name, price, capacity FROM class WHERE class_id = ?',
      [classId]
    );
    return rows[0] ?? null;
  }

  // ===================== GET SLOT CAPACITY & COUNT =====================

  static async getSlotCapacity(classId, date, timeslot) {
    const classRows = await db.query(
      'SELECT capacity FROM class WHERE class_id = ?',
      [classId]
    );
    const classRow = classRows[0];
    if (!classRow) return null;

    const countRows = await db.query(
      `SELECT COUNT(*) AS count FROM booking
       WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'Confirmed'`,
      [classId, date, timeslot]
    );
    const countRow = countRows[0];

    return { capacity: classRow.capacity, count: countRow.count };
  }

  // ===================== GET CANCELLED SLOTS =====================

  static async getCancelledSlots() {
    return db.query(`
      SELECT cc.cancel_id, cc.class_id, cc.cancel_date, cc.cancel_timeslot,
             cc.cancelled_at, c.class_name, s.name AS cancelled_by_name
      FROM cancel_class cc
      JOIN class c ON cc.class_id = c.class_id
      JOIN staff s ON cc.cancelled_by = s.staff_id
      ORDER BY cc.cancel_date DESC, cc.cancel_timeslot ASC
    `);
  }

  // ===================== CHECK IF SLOT IS CANCELLED =====================

  static async isSlotCancelled(classId, cancelDate, cancelTimeslot) {
    const rows = await db.query(
      `SELECT cancel_id FROM cancel_class
       WHERE class_id = ? AND DATE(cancel_date) = ? AND cancel_timeslot = ?`,
      [classId, cancelDate, cancelTimeslot]
    );
    return rows.length > 0;
  }

  // ===================== GET AFFECTED MEMBERS =====================
  // Returns members with confirmed bookings for a slot WITHOUT modifying
  // any booking records. Used by the cancel-class route so AutoRescheduleService
  // can reschedule them before the slot is marked as cancelled.

  static async getAffectedMembers(classId, cancelDate, cancelTimeslot) {
    return db.query(`
      SELECT b.booking_id, b.member_id, m.name AS member_name, c.class_name
      FROM booking b
      JOIN member m ON b.member_id = m.member_id
      JOIN class  c ON b.class_id  = c.class_id
      WHERE b.class_id = ?
        AND DATE(b.booking_date) = ?
        AND b.booking_time = ?
        AND b.status = 'Confirmed'
    `, [classId, cancelDate, cancelTimeslot]);
  }

  // ===================== CANCEL CLASS SLOT (staff) =====================
  // Inserts into cancel_class and marks any remaining confirmed bookings
  // as cancelled (catches any that AutoRescheduleService couldn't handle).

  static async cancelClassSlot(classId, cancelDate, cancelTimeslot, staffId) {
    // Mark any remaining confirmed bookings as cancelled
    // (members successfully rescheduled by AutoRescheduleService will
    //  already have a different booking_date/time so won't be affected)
    await db.query(
      `UPDATE booking SET status = 'Cancelled'
       WHERE class_id = ? AND DATE(booking_date) = ? AND booking_time = ? AND status = 'Confirmed'`,
      [classId, cancelDate, cancelTimeslot]
    );

    // Insert into cancel_class table
    await db.query(
      'INSERT INTO cancel_class (class_id, cancel_date, cancel_timeslot, cancelled_by) VALUES (?, ?, ?, ?)',
      [classId, cancelDate, cancelTimeslot, staffId]
    );
  }

  // ===================== CANCEL BOOKING (member) =====================

  static async cancelBooking(bookingId) {
    await db.query(
      `DELETE FROM booking WHERE booking_id = ?`,
      [bookingId]
    );
  }

  // ===================== RESCHEDULE BOOKING =====================

  static async rescheduleBooking({ bookingId, memberId, classId, newDate, newTime }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const cancelledRows = await connection.execute(
        `SELECT cancel_id FROM cancel_class
         WHERE class_id = ? AND DATE(cancel_date) = ? AND cancel_timeslot = ?`,
        [classId, newDate, newTime]
      );
      if (cancelledRows[0] && cancelledRows[0].length > 0) {
        await connection.rollback();
        throw new Error('This slot has been cancelled by staff');
      }

      const [classRows] = await connection.execute(
        'SELECT capacity FROM class WHERE class_id = ? FOR UPDATE',
        [classId]
      );
      if (!classRows || classRows.length === 0) {
        await connection.rollback();
        throw new Error('Class not found');
      }

      const [countRows] = await connection.execute(
        `SELECT COUNT(*) AS count FROM booking
         WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'Confirmed'`,
        [classId, newDate, newTime]
      );
      if (countRows[0].count >= classRows[0].capacity) {
        await connection.rollback();
        throw new Error('New slot is fully booked');
      }

      const duplicateRows = await connection.execute(
        `SELECT booking_id FROM booking
         WHERE member_id = ? AND class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'Confirmed'`,
        [memberId, classId, newDate, newTime]
      );
      if (duplicateRows[0] && duplicateRows[0].length > 0) {
        await connection.rollback();
        throw new Error('You already have a booking in this slot');
      }

      await connection.execute(
        'UPDATE booking SET booking_date = ?, booking_time = ? WHERE booking_id = ?',
        [newDate, newTime, bookingId]
      );

      await connection.commit();
    } catch (err) {
      try { await connection.rollback(); } catch (e) {}
      throw err;
    } finally {
      try { connection.release(); } catch (e) {}
    }
  }
}

module.exports = BookingModel;