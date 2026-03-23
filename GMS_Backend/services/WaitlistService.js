// services/WaitlistService.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles waitlist promotion when a confirmed booking is cancelled.
//
// Flow:
//   1. Member cancels confirmed booking
//   2. promoteNext() finds the first waiting member (lowest booking_id)
//   3. Captures their Stripe Payment Intent (charges their card)
//   4. Updates their booking status from 'Waiting' → 'Confirmed'
//   5. Sends them an in-app notice
// ─────────────────────────────────────────────────────────────────────────────

const stripe        = require('stripe')(require('../config/config').STRIPE.secretKey);
const BookingModel  = require('../models/Booking');
const NoticeModel   = require('../models/Notice');
const db            = require('../config/database');

const SYSTEM_STAFF_ID = 1;

class WaitlistService {

  // ══════════════════════════════════════════════════════════════════════════
  // PROMOTE NEXT — called after a confirmed booking is cancelled
  // ══════════════════════════════════════════════════════════════════════════

  static async promoteNext(classId, bookingDate, bookingTime) {
    // Find the first waiting member for this slot (lowest booking_id = joined first)
    const next = await BookingModel.getNextWaiting(classId, bookingDate, bookingTime);

    if (!next) {
      console.log(`[Waitlist] No waiting members for ${classId} ${bookingDate} ${bookingTime}`);
      return null;
    }

    console.log(
      `[Waitlist] Promoting member ${next.member_id} ` +
      `(booking ${next.booking_id}) from waitlist`
    );

    try {
      // Capture the pre-authorised Stripe payment — this actually charges the card
      await stripe.paymentIntents.capture(next.payment_intent_id);
      console.log(`[Waitlist] Captured payment intent ${next.payment_intent_id}`);
    } catch (err) {
      // If capture fails (e.g. card expired), skip this member and try the next
      console.error(
        `[Waitlist] Failed to capture payment for member ${next.member_id}:`, err.message
      );

      // Mark this waitlist entry as cancelled so we don't try again
      await BookingModel.cancelWaitlistEntry(next.booking_id);

      // Recursively try the next person in the waitlist
      return this.promoteNext(classId, bookingDate, bookingTime);
    }

    // Record the payment in the payment table
    await this._recordPromotedPayment(next);

    // Update booking status from Waiting → Confirmed
    await BookingModel.promoteFromWaitlist(next.booking_id);

    // Notify the member
    await this._notifyPromotion(next);

    console.log(`[Waitlist] Member ${next.member_id} successfully promoted.`);
    return next;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RECORD PROMOTED PAYMENT
  // ══════════════════════════════════════════════════════════════════════════

  static async _recordPromotedPayment(entry) {
    const PaymentModel = require('../models/Payment');
    // Assume amount is fixed or retrieved; for now, use a placeholder or query class price
    // Since we don't have amount here, need to get it from class or something.
    // For simplicity, assume amount is known, or add to entry.
    // In getNextWaiting, we can add price from class.
    // But to keep simple, let's add price to the select.

    // Update getNextWaiting to include price
    // But for now, hardcode or assume.

    // Actually, since it's waitlist, the amount was passed when joining, but not stored.
    // Perhaps store amount in booking or get from class.

    // To fix, let's modify getNextWaiting to join class and get price.

    // But for now, since the original had amount in recordWaitlistPayment, but now we need it.

    // Perhaps pass amount in the flow.

    // For simplicity, let's assume amount is 400 or get from class.

    // Let's update getNextWaiting to include c.price

    // Then use entry.price

    // Yes.

    // First, update getNextWaiting.

    // In Booking.js, add c.price AS class_price

    // Then in WaitlistService, use entry.class_price

    // Yes.

    await PaymentModel.recordPayment({
      paymentSource: 'booking',
      memberId: entry.member_id,
      applicationId: null,
      amount: entry.class_price,
      paymentMethod: 'Card',
      paymentIntentId: entry.payment_intent_id,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPIRE OLD WAITLIST ENTRIES — called by daily cron job
  // Cancels Payment Intents for slots that have already passed
  // ══════════════════════════════════════════════════════════════════════════

  static async expireOldEntries() {
    console.log('[Waitlist] Running expiry check at', new Date().toISOString());

    // Find all waiting bookings whose date has passed
    const expired = await db.query(`
      SELECT b.booking_id, b.member_id, b.class_id,
             DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date,
             b.booking_time, b.payment_intent_id, m.name AS member_name,
             c.class_name
      FROM booking b
      JOIN member  m ON m.member_id  = b.member_id
      JOIN class   c ON c.class_id   = b.class_id
      WHERE b.status = 'Waiting'
        AND b.booking_date < CURDATE()
    `);

    console.log(`[Waitlist] Found ${expired.length} expired waitlist entries.`);

    for (const entry of expired) {
      try {
        // Cancel the Stripe Payment Intent — member is never charged
        await stripe.paymentIntents.cancel(entry.payment_intent_id);
        console.log(
          `[Waitlist] Cancelled payment intent ${entry.payment_intent_id} ` +
          `for member ${entry.member_id}`
        );

        // Update booking status to Cancelled
        await BookingModel.cancelWaitlistEntry(entry.booking_id);

        // Notify member their waitlist spot expired
        await this._notifyExpiry(entry);
      } catch (err) {
        console.error(
          `[Waitlist] Failed to expire entry ${entry.booking_id}:`, err.message
        );
      }
    }

    return { expired: expired.length };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static async _notifyPromotion(entry) {
    try {
      await NoticeModel.createNotice({
        staff_id:    SYSTEM_STAFF_ID,
        title:       '🎉 You\'ve been promoted from the waitlist!',
        message:
          `Dear ${entry.member_name},\n\n` +
          `Great news! A spot has opened up in your ${entry.class_name} class ` +
          `on ${entry.booking_date} at ${entry.booking_time}.\n\n` +
          `Your booking has been automatically confirmed and your payment has been processed.\n\n` +
          `See you at the gym!`,
        posted_date: new Date().toISOString().split('T')[0],
        target_type: 'SELECTED',
        recipients:  [entry.member_id],
      });
    } catch (err) {
      console.warn(`[Waitlist] Failed to notify member ${entry.member_id}:`, err.message);
    }
  }

  static async _notifyExpiry(entry) {
    try {
      await NoticeModel.createNotice({
        staff_id:    SYSTEM_STAFF_ID,
        title:       'Waitlist Expired',
        message:
          `Dear ${entry.member_name},\n\n` +
          `Unfortunately, no spot became available in your ${entry.class_name} class ` +
          `on ${entry.booking_date} at ${entry.booking_time}.\n\n` +
          `Your waitlist entry has been removed and no payment has been taken.\n\n` +
          `You can book another available slot from the app.`,
        posted_date: new Date().toISOString().split('T')[0],
        target_type: 'SELECTED',
        recipients:  [entry.member_id],
      });
    } catch (err) {
      console.warn(`[Waitlist] Failed to notify member ${entry.member_id}:`, err.message);
    }
  }
}

module.exports = WaitlistService;