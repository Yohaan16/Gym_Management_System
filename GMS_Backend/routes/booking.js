const express               = require('express');
const router                = express.Router();
const BookingModel          = require('../models/Booking');
const BookingService        = require('../services/BookingService');
const PaymentService        = require('../services/PaymentService');
const WaitlistService       = require('../services/WaitlistService');
const AutoRescheduleService = require('../services/AutoRescheduleService');

const asyncHandler = fn => (req, res) =>
  fn(req, res).catch(err => res.status(500).json({ success: false, message: err.message }));

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
======================= */
router.post('/cancel-class', asyncHandler(async (req, res) => {
  const { classId, cancelDate, cancelTimeslot } = req.body;
  const staffId = req.user.id;

  if (!classId || !cancelDate || !cancelTimeslot || !staffId)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  const alreadyCancelled = await BookingModel.isSlotCancelled(classId, cancelDate, cancelTimeslot);
  if (alreadyCancelled)
    return res.status(400).json({ success: false, message: 'Slot already cancelled' });

  const affectedMembers = await BookingModel.getAffectedMembers(classId, cancelDate, cancelTimeslot);

  let rescheduleResult = { rescheduled: 0, failed: 0, results: [] };
  if (affectedMembers.length > 0) {
    rescheduleResult = await AutoRescheduleService.rescheduleFromCancellation(
      classId, cancelDate, cancelTimeslot, affectedMembers
    );
  }

  await BookingModel.cancelClassSlot(classId, cancelDate, cancelTimeslot, staffId);

  res.json({
    message:            'Class slot cancelled',
    affectedBookings:   affectedMembers.length,
    rescheduled:        rescheduleResult.rescheduled,
    couldNotReschedule: rescheduleResult.failed,
    details:            rescheduleResult.results,
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
   After cancelling, automatically promotes the first waitlist member.
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

  // Cancel the booking
  await BookingModel.cancelBooking(bookingId);

  // Automatically promote the next person from the waitlist
  // This runs asynchronously — we don't make the member wait for it
  WaitlistService.promoteNext(
    booking.class_id,
    booking.booking_date,
    booking.booking_time
  ).catch(err => console.error('[Waitlist] promoteNext error:', err.message));

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
    classId:  booking.class_id,
    newDate,
    newTime,
  });

  // Also promote from waitlist for the old slot since a spot just freed up
  WaitlistService.promoteNext(
    booking.class_id,
    booking.booking_date,
    booking.booking_time
  ).catch(err => console.error('[Waitlist] promoteNext error:', err.message));

  res.json({ success: true, message: 'Booking rescheduled successfully' });
}));

/* =======================
   WAITLIST — JOIN
   Step 1: Create waitlist booking + Payment Intent (manual capture)
   Flutter then presents the Stripe payment sheet using the clientSecret.
   Step 2: After payment sheet completes, call POST /waitlist/confirm
======================= */
router.post('/waitlist', asyncHandler(async (req, res) => {
  const { member_id, class_id, booking_date, booking_time, amount } = req.body;

  if (!member_id || !class_id || !booking_date || !booking_time || !amount)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  // Insert Waiting booking row
  const bookingId = await BookingModel.joinWaitlist({
    member_id, class_id, booking_date, booking_time,
  });

  // Create Stripe Payment Intent with manual capture
  const { clientSecret, paymentIntentId } =
    await PaymentService.createWaitlistPaymentIntent(
      amount, class_id, member_id, bookingId
    );

  // Update the booking with the payment intent ID
  await BookingModel.updateBookingPaymentIntent(bookingId, paymentIntentId);

  res.status(201).json({
    success:         true,
    booking_id:      bookingId,
    clientSecret,               // Flutter uses this to present payment sheet
    paymentIntentId,
    message:         'Joined waitlist. Complete payment to secure your position.',
  });
}));

/* =======================
   WAITLIST — CONFIRM PAYMENT
   Called after Flutter's Stripe payment sheet completes successfully.
   Verifies the Payment Intent is authorised (no payment record yet).
======================= */
router.post('/waitlist/confirm', asyncHandler(async (req, res) => {
  const { member_id, booking_id, amount, payment_intent_id, payment_method } = req.body;

  if (!member_id || !booking_id || !amount || !payment_intent_id)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  // Verify the Payment Intent exists and is in requires_capture state
  const stripe = require('stripe')(require('../config/config').STRIPE.secretKey);
  const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);
  if (!['requires_capture', 'succeeded'].includes(paymentIntent.status)) {
    return res.status(400).json({ success: false, message: 'Payment authorisation failed' });
  }

  // Derive queue position
  const waitlist = await BookingModel.getMemberWaitlist(member_id);
  const entry    = waitlist.find(w => w.booking_id === booking_id);

  res.json({
    success:        true,
    message:        'You are on the waitlist. We will notify you if a spot opens.',
    queue_position: entry?.queue_position ?? null,
  });
}));

/* =======================
   WAITLIST — MEMBER'S ENTRIES
======================= */
router.get('/waitlist/member/:memberId', asyncHandler(async (req, res) => {
  const waitlist = await BookingModel.getMemberWaitlist(req.params.memberId);
  res.json(waitlist);
}));

/* =======================
   WAITLIST — LEAVE
   Member leaves the waitlist — cancels their Payment Intent so no charge occurs.
======================= */
router.delete('/waitlist/:bookingId', asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const memberId = parseInt(req.headers['x-member-id'], 10);

  if (!bookingId || !memberId)
    return res.status(400).json({ success: false, message: 'Missing required fields' });

  const booking = await BookingModel.getBookingById(bookingId, memberId);
  if (!booking)
    return res.status(404).json({ success: false, message: 'Waitlist entry not found' });
  if (booking.status !== 'Waiting')
    return res.status(400).json({ success: false, message: 'Booking is not a waitlist entry' });

  // Get the payment intent to cancel it
  const stripe = require('stripe')(require('../config/config').STRIPE.secretKey);

  if (booking.payment_intent_id) {
    try {
      await stripe.paymentIntents.cancel(booking.payment_intent_id);
    } catch (err) {
      console.warn('[Waitlist] Could not cancel payment intent:', err.message);
    }
  }

  await BookingModel.cancelWaitlistEntry(bookingId);

  res.json({ success: true, message: 'Removed from waitlist. No payment has been taken.' });
}));

module.exports = router;