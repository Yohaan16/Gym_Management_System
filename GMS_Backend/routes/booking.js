const express               = require('express');
const router                = express.Router();
const BookingModel          = require('../models/Booking');
const BookingService        = require('../services/BookingService');
const AutoRescheduleService = require('../services/AutoRescheduleService');

const asyncHandler = fn => (req, res) =>
  fn(req, res).catch(err => res.status(500).json({ success: false, message: err.message }));

const today = () => new Date().toISOString().split('T')[0];

/* =======================
   CLASS DETAILS
======================= */
router.get('/class/:classId', asyncHandler(async (req, res) => {
  const data = await BookingModel.getClassDetails(req.params.classId);
  if (!data) return res.status(404).json({ error: 'Class not found' });
  res.json(data);
}));

/* =======================
   MEMBER BOOKINGS
======================= */
router.get('/member/:memberId', asyncHandler(async (req, res) => {
  const bookings = await BookingModel.getMemberBookings(req.params.memberId);
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
   ALL BOOKINGS
======================= */
router.get('/retrieve', asyncHandler(async (_, res) => {
  const bookings = await BookingModel.getAllBookings();
  res.json(bookings);
}));

/* =======================
   CANCEL CLASS SLOT (staff)
   Instead of cancelling member bookings and sending cancellation notices,
   AutoRescheduleService reschedules each member to their optimal alternative
   slot using the Hungarian Algorithm, then sends a rescheduling notice.
   Any members that could not be rescheduled (no available slots) are
   cancelled as a fallback.
======================= */
router.post('/cancel-class', asyncHandler(async (req, res) => {
  const { classId, cancelDate, cancelTimeslot } = req.body;
  const staffId = req.user.id;

  if (!classId || !cancelDate || !cancelTimeslot || !staffId)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  const alreadyCancelled = await BookingModel.isSlotCancelled(classId, cancelDate, cancelTimeslot);
  if (alreadyCancelled)
    return res.status(400).json({ success: false, message: 'Slot already cancelled' });

  // Step 1 — fetch affected members BEFORE cancelling the slot
  const affectedMembers = await BookingModel.getAffectedMembers(
    classId, cancelDate, cancelTimeslot
  );

  // Step 2 — reschedule affected members via Hungarian Algorithm
  let rescheduleResult = { rescheduled: 0, failed: 0, results: [] };
  if (affectedMembers.length > 0) {
    rescheduleResult = await AutoRescheduleService.rescheduleFromCancellation(
      classId, cancelDate, cancelTimeslot, affectedMembers
    );
  }

  // Step 3 — mark slot as cancelled (catches any members that couldn't be rescheduled)
  await BookingModel.cancelClassSlot(classId, cancelDate, cancelTimeslot, staffId);

  res.json({
    message: 'Class slot cancelled',
    affectedBookings:  affectedMembers.length,
    rescheduled:       rescheduleResult.rescheduled,
    couldNotReschedule: rescheduleResult.failed,
    details:           rescheduleResult.results,
  });
}));

/* =======================
   CANCELLED SLOTS
======================= */
router.get('/cancelled-slots', asyncHandler(async (_, res) => {
  const slots = await BookingModel.getCancelledSlots();
  res.json(slots);
}));

/* =======================
   SLOT CAPACITY & COUNT
======================= */
router.get('/slot-capacity/:classId/:date/:timeslot', asyncHandler(async (req, res) => {
  let { classId, date, timeslot } = req.params;
  try { timeslot = decodeURIComponent(timeslot); } catch (_) {}

  const data = await BookingModel.getSlotCapacity(classId, date, timeslot);
  if (!data) return res.status(404).json({ success: false, message: 'Class not found' });
  res.json(data);
}));

router.get('/slot-capacity', asyncHandler(async (req, res) => {
  const { classId, date, timeslot } = req.query;
  if (!classId || !date || !timeslot)
    return res.status(400).json({ success: false, message: 'Missing required parameters' });

  const data = await BookingModel.getSlotCapacity(classId, date, timeslot);
  if (!data) return res.status(404).json({ success: false, message: 'Class not found' });
  res.json(data);
}));

/* =======================
   CANCEL BOOKING (member)
======================= */
router.delete('/:bookingId', asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const memberId = parseInt(req.headers['x-member-id'], 10);

  if (!bookingId || !memberId)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  const booking = await BookingModel.getBookingById(bookingId, memberId);
  if (!booking)
    return res.status(404).json({ success: false, message: 'Booking not found' });
  if (booking.status !== 'Confirmed')
    return res.status(400).json({ success: false, message: 'Booking is not confirmed' });

  await BookingModel.cancelBooking(bookingId);
  res.json({ success: true, message: 'Booking cancelled successfully' });
}));

/* =======================
   RESCHEDULE BOOKING
======================= */
router.put('/:bookingId/reschedule', asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const memberId = parseInt(req.headers['x-member-id'], 10);
  const { newDate, newTime } = req.body;

  if (!bookingId || !memberId || !newDate || !newTime)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  const booking = await BookingModel.getBookingById(bookingId, memberId);
  if (!booking)
    return res.status(404).json({ success: false, message: 'Booking not found' });
  if (booking.status !== 'Confirmed')
    return res.status(400).json({ success: false, message: 'Only confirmed bookings can be rescheduled' });

  await BookingModel.rescheduleBooking({
    bookingId,
    memberId,
    classId: booking.class_id,
    newDate,
    newTime,
  });

  res.json({ success: true, message: 'Booking rescheduled successfully' });
}));

module.exports = router;