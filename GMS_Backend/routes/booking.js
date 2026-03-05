const express = require('express');
const router = express.Router();
const db = require('../config/database');
const BookingService = require('../services/BookingService');
const NoticeModel = require('../models/Notice');

const asyncHandler = fn => (req, res) =>
  fn(req, res).catch(err => res.status(500).json({ error: err.message }));

const today = () => new Date().toISOString().split('T')[0];

/* =======================
   CLASS DETAILS
======================= */
router.get('/class/:classId', asyncHandler(async (req, res) => {
  const [data] = await db.query(
    'SELECT class_id, class_name, price, capacity FROM class WHERE class_id = ?',
    [req.params.classId]
  );
  if (!data) return res.status(404).json({ error: 'Class not found' });
  res.json(data);
}));

/* =======================
   MEMBER BOOKINGS
======================= */
router.get('/member/:memberId', asyncHandler(async (req, res) => {
  const bookings = await db.query(
    `SELECT booking_id, class_id, booking_date, booking_time, status
     FROM booking
     WHERE member_id = ? AND LOWER(status) = 'confirmed'`,
    [req.params.memberId]
  );
  res.json(bookings);
}));

/* =======================
   CREATE BOOKING
======================= */
router.post('/', asyncHandler(async (req, res) => {
  const result = await BookingService.bookClass(req.body);
  res.status(201).json(result);
}));


/* =======================
   ALL BOOKINGS ##
======================= */
router.get('/retrieve', asyncHandler(async (_, res) => {
  const bookings = await db.query(`
    SELECT b.booking_id, b.class_id, b.booking_date, b.booking_time, b.status, m.member_id, m.name, m.email, m.phone, c.class_name
    FROM booking b
    JOIN member m ON b.member_id = m.member_id
    JOIN class c ON b.class_id = c.class_id
    ORDER BY b.booking_date DESC, b.booking_time ASC
  `);
  res.json(bookings);
}));

/* =======================
   CANCEL CLASS SLOT ##
======================= */
router.post('/cancel-class', asyncHandler(async (req, res) => {
  const { classId, cancelDate, cancelTimeslot } = req.body;
  const staffId = req.user.id; // From JWT token

  if (!classId || !cancelDate || !cancelTimeslot || !staffId)
    return res.status(400).json({ error: 'Missing required fields' });

  try {
    const existing = await db.query(
      `SELECT * FROM cancel_class
       WHERE class_id = ? AND DATE(cancel_date) = ? AND cancel_timeslot = ?`,
      [classId, cancelDate, cancelTimeslot]
    );
    if (existing.length) return res.status(400).json({ error: 'Slot already cancelled' });

    const affected = await db.query(`
      SELECT b.member_id, m.name AS member_name, c.class_name
      FROM booking b
      JOIN member m ON b.member_id = m.member_id
      JOIN class c ON b.class_id = c.class_id
      WHERE b.class_id = ?
        AND DATE(b.booking_date) = ?
        AND b.booking_time = ?
        AND b.status = 'confirmed'
    `, [classId, cancelDate, cancelTimeslot]);

    await db.query(
      `UPDATE booking
       SET status = 'cancelled'
       WHERE class_id = ? AND DATE(booking_date) = ? AND booking_time = ?`,
      [classId, cancelDate, cancelTimeslot]
    );

    await db.query(
      'INSERT INTO cancel_class (class_id, cancel_date, cancel_timeslot, cancelled_by) VALUES (?, ?, ?, ?)',
      [classId, cancelDate, cancelTimeslot, staffId]
    );

    for (const b of affected) {
      try {
        await NoticeModel.createNotice({
          staff_id: staffId,
          title: 'Class Cancellation Notice',
          message:
            `Dear ${b.member_name},\n\n` +
            `Your ${b.class_name} class on ${cancelDate} at ${cancelTimeslot} has been cancelled.\n\nRefund available at front desk.`,
          posted_date: today(),
          target_type: 'SELECTED',
          recipients: [b.member_id]
        });
      } catch (noticeError) {
      }
    }

    res.json({ message: 'Class slot cancelled', affectedBookings: affected.length });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to cancel class' });
  }
}));

/* =======================
   CANCELLED SLOTS ##
======================= */
router.get('/cancelled-slots', asyncHandler(async (_, res) => {
  const slots = await db.query(`
    SELECT cc.cancel_id, cc.class_id, cc.cancel_date, cc.cancel_timeslot,
           cc.cancelled_at, c.class_name, s.name AS cancelled_by_name
    FROM cancel_class cc
    JOIN class c ON cc.class_id = c.class_id
    JOIN staff s ON cc.cancelled_by = s.staff_id
    ORDER BY cc.cancel_date DESC, cc.cancel_timeslot ASC
  `);
  res.json(slots);
}));

/* =======================
   SLOT CAPACITY & COUNT
======================= */
router.get('/slot-capacity/:classId/:date/:timeslot', asyncHandler(async (req, res) => {
  let { classId, date, timeslot } = req.params;
  try { timeslot = decodeURIComponent(timeslot); } catch (_) {}



  req._slotQuery = { classId, date, timeslot };
  return slotCapacityHandler(req, res);
}));

router.get('/slot-capacity', asyncHandler(async (req, res) => {
  return slotCapacityHandler(req, res);
}));

async function slotCapacityHandler(req, res) {
  const { classId, date, timeslot } = req._slotQuery || {
    classId: req.query.classId,
    date: req.query.date,
    timeslot: req.query.timeslot
  };

  if (!classId || !date || !timeslot) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }


  const [classRow] = await db.query('SELECT capacity FROM class WHERE class_id = ?', [classId]);
  if (!classRow) return res.status(404).json({ error: 'Class not found' });


  const [countRow] = await db.query(
    `SELECT COUNT(*) AS count FROM booking
     WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'confirmed'`,
    [classId, date, timeslot]
  );

  return res.json({ capacity: classRow.capacity, count: countRow.count });
}

module.exports = router;
