const express = require('express');
const router = express.Router();

const UserModel = require('../models/User');
const PaymentService = require('../services/PaymentService');
const { asyncHandler, ValidationError } = require('../utils/errorHandler');
const { validateRequired } = require('../middleware/common');

/* ===================== REGISTRATION ===================== */

router.post('/registration', asyncHandler(async (req, res) => {
  const result = await UserModel.createRegistration(req.body);
  res.status(201).json({
    success: true,
    message: 'Registration application submitted successfully',
    data: result
  });
}));

/* ===================== REGISTRATION PAYMENT ===================== */

router.post('/payments/create-payment-intent', asyncHandler(async (req, res) => {
  const { amount, applicationId } = req.body;

  const result = await PaymentService.createPaymentIntent(amount, applicationId);
  res.json({
    success: true,
    data: result
  });
}));


router.post('/payments/record-payment', validateRequired(['applicationId', 'amount']),
  asyncHandler(async (req, res) => {
    const { applicationId, paymentIntentId, amount, paymentMethod = 'Card' } = req.body;

    const result = await PaymentService.recordPayment({
      applicationId,
      paymentIntentId,
      amount,
      paymentMethod
    });
    res.json({
      success: true,
      data: result
    });
  })
);

module.exports = router;
