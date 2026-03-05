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
  static async createIntent({ amount, metadata, description }) {
    const intent = await stripe.paymentIntents.create({
      amount: cents(amount),
      currency: 'mur',
      metadata,
      description
    });
    return { clientSecret: intent.client_secret, paymentIntentId: intent.id };
  }

  /* =======================
     REGISTRATION PAYMENTS
  ======================= */
  static async createPaymentIntent(amount, applicationId) {
    required(amount, applicationId);

    return this.createIntent({
      amount,
      metadata: { application_id: applicationId, payment_source: 'registration' },
      description: `Registration payment for application #${applicationId}`
    });
  }

  static async recordPayment({ applicationId, amount, paymentMethod = 'Card', paymentIntentId }) {
    if (!applicationId || !amount) {
      applicationId = await this.getLatestPendingApplication();
    }

    // Verify Stripe payment BEFORE recording (if paymentIntentId provided)
    if (paymentIntentId) {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      
      if (paymentIntent.status !== 'succeeded') {
        throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
      }

      const intendedAmount = Math.round(amount * 100); // Convert to cents
      if (paymentIntent.amount !== intendedAmount) {
        throw new ValidationError(`Payment amount mismatch. Expected ${intendedAmount} cents, got ${paymentIntent.amount} cents`);
      }
    }

    await PaymentModel.recordPayment({
      paymentSource: 'registration',
      applicationId,
      memberId: null,
      amount,
      paymentMethod
    });

    // Just update the payment status, don't create member yet
    // Member will be created when they first login or when admin approves
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
      metadata: { class_id: classId, member_id: memberId, payment_source: 'class_booking' },
      description: `Class booking payment for class #${classId}`
    });
  }

  static async recordBookingPayment({ memberId, classId, amount, paymentMethod = 'Card', paymentIntentId }) {
    required(memberId, classId, amount, paymentIntentId);

    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status !== 'succeeded') {
      throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
    }

    const intendedAmount = Math.round(amount * 100); // Convert to cents
    if (paymentIntent.amount !== intendedAmount) {
      throw new ValidationError(`Payment amount mismatch. Expected ${intendedAmount} cents, got ${paymentIntent.amount} cents`);
    }

    await PaymentModel.recordPayment({
      paymentSource: 'booking',
      memberId,
      applicationId: null,
      amount,
      paymentMethod,
      stripePaymentIntentId: paymentIntentId
    });

    return { message: 'Booking payment completed', payment_status: 'completed' };
  }

  /* =======================
     MEMBERSHIP PAYMENTS
  ======================= */
  static async createMembershipPaymentIntent(amount, memberId, membershipType) {
    required(amount, memberId, membershipType);

    return this.createIntent({
      amount,
      metadata: {
        member_id: memberId,
        membership_type: membershipType,
        payment_source: 'membership_renewal'
      },
      description: `Membership renewal for ${membershipType}`
    });
  }

  static async recordMembershipPayment({ memberId, membershipType, paymentIntentId, amount, paymentMethod = 'Card' }) {
    required(memberId, membershipType, paymentIntentId, amount);

    // Verify Stripe payment
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status !== 'succeeded') {
      throw new ValidationError(`Payment not completed. Status: ${paymentIntent.status}`);
    }

    const intendedAmount = Math.round(amount * 100); // Convert to cents
    if (paymentIntent.amount !== intendedAmount) {
      throw new ValidationError(`Payment amount mismatch. Expected ${intendedAmount} cents, got ${paymentIntent.amount} cents`);
    }

    // Record payment in database
    await PaymentModel.recordPayment({
      paymentSource: 'membership renewal',
      memberId,
      applicationId: null,
      amount,
      paymentMethod
    });

    // Renew the membership
    const MembershipModel = require('../models/Membership');
    await MembershipModel.renewMembership(memberId, membershipType);

    // Get updated membership info with days_remaining calculated
    const updatedMembership = await MembershipModel.getCurrentMembership(memberId);

    return {
      message: 'Membership renewed successfully',
      payment_status: 'completed',
      membership: updatedMembership
    };
  }

  static async handleSuccessfulPayment(paymentIntent) {
    const applicationId = paymentIntent.metadata.application_id;
    const amount = paymentIntent.amount / 100;

    await PaymentModel.recordCardPayment(applicationId, amount, paymentIntent.id);
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
      memberId: null,
      amount: AMOUNT,
      paymentMethod
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
