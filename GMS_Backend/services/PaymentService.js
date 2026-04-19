const stripe = require('stripe')(require('../config/config').STRIPE.secretKey);
const PaymentModel = require('../models/Payment');
const { ValidationError } = require('../utils/errorHandler');

const cents = amount => Math.round(amount * 100);
const required = (...args) => {
  if (args.some(v => v === undefined || v === null))
    throw new ValidationError('Missing required fields');
};

class PaymentService {

  /* =======================
     STRIPE HELPERS
  ======================= */
  static async createIntent({ amount, metadata, description, captureMethod = 'automatic' }) {
    try {
      const intent = await stripe.paymentIntents.create({
        amount:         cents(amount),
        currency:       'mur',
        metadata,
        description,
        capture_method: captureMethod,
      });
      console.log('Created payment intent:', intent.id, 'client_secret present:', !!intent.client_secret);
      return { clientSecret: intent.client_secret, paymentIntentId: intent.id };
    } catch (stripeError) {
      if (stripeError.type === 'StripeInvalidRequestError') {
        throw new ValidationError(`Invalid payment request: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeAPIError') {
        throw new ValidationError(`Stripe API error: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeConnectionError') {
        throw new ValidationError('Payment service temporarily unavailable');
      }
      if (stripeError.type === 'StripeAuthenticationError') {
        throw new ValidationError('Payment service configuration error');
      }
      // Re-throw other Stripe errors as operational
      throw new ValidationError(`Payment creation failed: ${stripeError.message}`);
    }
  }

  /* =======================
     REGISTRATION PAYMENTS
  ======================= */
  static async createPaymentIntent(amount, applicationId) {
    required(amount, applicationId);
    return this.createIntent({
      amount,
      metadata:    { application_id: applicationId, payment_source: 'registration' },
      description: `Registration payment for application #${applicationId}`,
    });
  }

  static async recordPayment({ applicationId, amount, paymentMethod = 'Card', paymentIntentId }) {
    if (!applicationId || !amount) {
      applicationId = await this.getLatestPendingApplication();
    }

    if (paymentIntentId) {
      try {
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
        if (paymentIntent.status !== 'succeeded') {
          throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
        }
        const intendedAmount = Math.round(amount * 100);
        if (paymentIntent.amount !== intendedAmount) {
          throw new ValidationError(`Payment amount mismatch. Expected: ${intendedAmount}, Got: ${paymentIntent.amount}`);
        }
      } catch (stripeError) {
        if (stripeError.type === 'StripeInvalidRequestError') {
          throw new ValidationError(`Invalid payment intent: ${stripeError.message}`);
        }
        if (stripeError.type === 'StripeAPIError') {
          throw new ValidationError(`Stripe API error: ${stripeError.message}`);
        }
        if (stripeError.type === 'StripeConnectionError') {
          throw new ValidationError('Payment service temporarily unavailable');
        }
        if (stripeError.type === 'StripeAuthenticationError') {
          throw new ValidationError('Payment service configuration error');
        }
        // Re-throw other Stripe errors as operational
        throw new ValidationError(`Payment verification failed: ${stripeError.message}`);
      }
    }

    await PaymentModel.recordPayment({
      paymentSource: 'registration',
      applicationId,
      memberId: null,
      amount,
      paymentMethod,
      paymentIntentId,
    });

    await PaymentModel.updateRegistrationPaymentStatus(applicationId, 'Approved');
    return { message: 'Registration payment completed', payment_status: 'completed' };
  }

  static async getLatestPendingApplication() {
    const db = require('../config/database');
    const [row] = await db.query(`
      SELECT ra.application_id
      FROM registration_application ra
      LEFT JOIN payment p ON ra.application_id = p.application_id
      WHERE ra.payment = 'Pending' AND p.payment_id IS NULL
      ORDER BY ra.application_date DESC
      LIMIT 1
    `);
    if (!row) throw new ValidationError('No pending registration found');
    return row.application_id;
  }

  /* =======================
     CLASS BOOKINGS
  ======================= */
  static async createClassBookingPaymentIntent(amount, classId, memberId) {
    required(amount, classId, memberId);
    return this.createIntent({
      amount,
      metadata:    { class_id: classId, member_id: memberId, payment_source: 'class_booking' },
      description: `Class booking payment for class #${classId}`,
    });
  }

  static async recordBookingPayment({ memberId, classId, amount, paymentMethod = 'Card', paymentIntentId }) {
    required(memberId, classId, amount, paymentIntentId);
    console.log('recordBookingPayment called with paymentIntentId:', paymentIntentId);

    try {
      console.log('Retrieving payment intent...');
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      console.log('Payment intent retrieved:', paymentIntent.status);
      console.log('Payment intent details:', {
        id: paymentIntent.id,
        status: paymentIntent.status,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        client_secret: paymentIntent.client_secret ? 'present' : 'missing',
        last_payment_error: paymentIntent.last_payment_error,
      });
      if (paymentIntent.status !== 'succeeded') {
        throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
      }
      const intendedAmount = Math.round(amount * 100);
      if (paymentIntent.amount !== intendedAmount) {
        throw new ValidationError(`Payment amount mismatch. Expected: ${intendedAmount}, Got: ${paymentIntent.amount}`);
      }
    } catch (stripeError) {
      console.log('Stripe error caught:', stripeError.type, stripeError.message, stripeError.constructor.name);
      if (stripeError.type === 'StripeInvalidRequestError') {
        throw new ValidationError(`Invalid payment intent: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeAPIError') {
        throw new ValidationError(`Stripe API error: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeConnectionError') {
        throw new ValidationError('Payment service temporarily unavailable');
      }
      if (stripeError.type === 'StripeAuthenticationError') {
        throw new ValidationError('Payment service configuration error');
      }
      // Re-throw other Stripe errors as operational
      throw new ValidationError(`Payment verification failed: ${stripeError.message}`);
    }

    await PaymentModel.recordPayment({
      paymentSource: 'booking',
      memberId,
      applicationId: null,
      amount,
      paymentMethod,
      paymentIntentId,
    });

    return { message: 'Booking payment completed', payment_status: 'completed' };
  }

  /* =======================
     WAITLIST PAYMENTS
     Uses capture_method: 'manual' — card is authorised but NOT charged yet.
     Funds are captured automatically when the member is promoted from
     the waitlist via WaitlistService.promoteNext().
  ======================= */

  /**
   * Creates a Payment Intent with manual capture for a waitlist entry.
   * The card is authorised (funds reserved) but not charged until promotion.
   *
   * @param {number} amount     — class price
   * @param {number} classId
   * @param {number} memberId
   * @param {number} bookingId  — the newly created Waiting booking ID
   */
  static async createWaitlistPaymentIntent(amount, classId, memberId, bookingId) {
    required(amount, classId, memberId, bookingId);

    return this.createIntent({
      amount,
      metadata: {
        class_id:       classId,
        member_id:      memberId,
        booking_id:     bookingId,
        payment_source: 'waitlist',
      },
      description:   `Waitlist hold for class #${classId} — booking #${bookingId}`,
      captureMethod: 'manual', // ← key: authorise only, do not charge yet
    });
  }

  /**
   * Records the waitlist payment intent in the payment table.
   * Called after the member completes the Stripe payment sheet.
   * Status will remain as authorised (not captured) until promotion.
   *
   * @param {object} params
   * @param {number} params.memberId
   * @param {number} params.bookingId   — the Waiting booking ID
   * @param {number} params.amount
   * @param {string} params.paymentIntentId
   * @param {string} params.paymentMethod
   */
  static async recordWaitlistPayment({
    memberId, bookingId, amount,
    paymentIntentId, paymentMethod = 'Card',
  }) {
    required(memberId, bookingId, amount, paymentIntentId);

    // Verify the Payment Intent exists and is in requires_capture state
    // (meaning the card was authorised successfully)
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (!['requires_capture', 'succeeded'].includes(paymentIntent.status)) {
        throw new ValidationError(
          `Waitlist payment authorisation failed. Status: ${paymentIntent.status}`
        );
      }
    } catch (stripeError) {
      if (stripeError.type === 'StripeInvalidRequestError') {
        throw new ValidationError(`Invalid payment intent: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeAPIError') {
        throw new ValidationError(`Stripe API error: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeConnectionError') {
        throw new ValidationError('Payment service temporarily unavailable');
      }
      if (stripeError.type === 'StripeAuthenticationError') {
        throw new ValidationError('Payment service configuration error');
      }
      // Re-throw other Stripe errors as operational
      throw new ValidationError(`Payment verification failed: ${stripeError.message}`);
    }

    await PaymentModel.recordPayment({
      paymentSource:   'waitlist',
      memberId,
      applicationId:   null,
      amount,
      paymentMethod,
      paymentIntentId,
      bookingId,       // link payment to the waiting booking
    });

    return { message: 'Waitlist payment authorised', payment_status: 'authorised' };
  }

  /* =======================
     MEMBERSHIP PAYMENTS
  ======================= */
  static async createMembershipPaymentIntent(amount, memberId, membershipType) {
    required(amount, memberId, membershipType);
    return this.createIntent({
      amount,
      metadata: {
        member_id:       memberId,
        membership_type: membershipType,
        payment_source:  'membership_renewal',
      },
      description: `Membership renewal for ${membershipType}`,
    });
  }

  static async recordMembershipPayment({ memberId, membershipType, paymentIntentId, amount, paymentMethod = 'Card' }) {
    required(memberId, membershipType, paymentIntentId, amount);

    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (paymentIntent.status !== 'succeeded') {
        throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
      }
      const intendedAmount = Math.round(amount * 100);
      if (paymentIntent.amount !== intendedAmount) {
        throw new ValidationError(`Payment amount mismatch. Expected: ${intendedAmount}, Got: ${paymentIntent.amount}`);
      }
    } catch (stripeError) {
      if (stripeError.type === 'StripeInvalidRequestError') {
        throw new ValidationError(`Invalid payment intent: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeAPIError') {
        throw new ValidationError(`Stripe API error: ${stripeError.message}`);
      }
      if (stripeError.type === 'StripeConnectionError') {
        throw new ValidationError('Payment service temporarily unavailable');
      }
      if (stripeError.type === 'StripeAuthenticationError') {
        throw new ValidationError('Payment service configuration error');
      }
      // Re-throw other Stripe errors as operational
      throw new ValidationError(`Payment verification failed: ${stripeError.message}`);
    }

    await PaymentModel.recordPayment({
      paymentSource: 'membership renewal',
      memberId,
      applicationId: null,
      amount,
      paymentMethod,
      paymentIntentId,
    });

    const MembershipModel = require('../models/Membership');
    await MembershipModel.renewMembership(memberId, membershipType);
    const updatedMembership = await MembershipModel.getCurrentMembership(memberId);

    return {
      message:          'Membership renewed successfully',
      payment_status:   'completed',
      membership:       updatedMembership,
    };
  }

  static async handleSuccessfulPayment(paymentIntent) {
    const applicationId = paymentIntent.metadata.application_id;
    const amount        = paymentIntent.amount / 100;

    await PaymentModel.recordPayment({
      paymentSource:   'registration',
      applicationId,
      memberId:        null,
      amount,
      paymentMethod:   'Card',
      paymentIntentId: paymentIntent.id,
    });
    await PaymentModel.updateRegistrationPaymentStatus(applicationId, 'Approved');
  }

  /* =======================
     STAFF PAYMENTS
  ======================= */
  static async recordStaffPayment(applicationId, paymentMethod) {
    required(applicationId, paymentMethod);
    const AMOUNT = 1000.0;
    await PaymentModel.recordPayment({
      paymentSource: 'registration',
      applicationId,
      memberId:      null,
      amount:        AMOUNT,
      paymentMethod,
    });
    await PaymentModel.updateRegistrationPaymentStatus(applicationId, 'Approved');
    return { message: 'Staff payment recorded', payment_status: 'completed' };
  }

  /* =======================
     REPORTING
  ======================= */
  static getMonthlyRevenue = PaymentModel.getMonthlyRevenue;
}

module.exports = PaymentService;