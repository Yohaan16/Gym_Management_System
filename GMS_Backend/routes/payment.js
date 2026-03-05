const express = require('express');
const PaymentService = require('../services/PaymentService');
const { asyncHandler } = require('../utils/errorHandler');
const { validateRequired } = require('../middleware/common');

const router = express.Router();

// Create payment intent for registration
router.post('/create-payment-intent', asyncHandler(async (req, res) => {
  const { amount, applicationId } = req.body;

  const result = await PaymentService.createPaymentIntent(amount, applicationId);
  res.json(result);
}));

// Create payment intent for class booking
router.post('/create-class-booking-payment-intent', validateRequired(['amount', 'classId', 'memberId']),
  asyncHandler(async (req, res) => {
    const { amount, classId, memberId } = req.body;
    const result = await PaymentService.createClassBookingPaymentIntent(amount, classId, memberId);
    res.json(result);
  })
);

// Record booking payment after successful Stripe payment
router.post('/record-booking-payment', validateRequired(['memberId', 'classId', 'amount']),
  asyncHandler(async (req, res) => {
    const { memberId, classId, paymentIntentId, amount, paymentMethod = 'Card' } = req.body;
    const result = await PaymentService.recordBookingPayment({
      memberId,
      classId,
      paymentIntentId,
      amount,
      paymentMethod
    });

    res.json(result);
  })
);

// Record staff-approved payment for registration
router.post('/record-staff-payment', validateRequired(['applicationId', 'paymentMethod']),
  asyncHandler(async (req, res) => {
    const { applicationId, paymentMethod } = req.body;

    const result = await PaymentService.recordStaffPayment(applicationId, paymentMethod);
    res.json(result);
  })
);


module.exports = router;