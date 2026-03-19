const express = require('express');
const router  = express.Router();
const path    = require('path');

const UserModel      = require('../models/User');
const PaymentService = require('../services/PaymentService');
const { upload, requirePhoto } = require('../middleware/upload');
const { asyncHandler } = require('../utils/errorHandler');
const { validateRequired } = require('../middleware/common');

/* ===================== REGISTRATION ===================== */

// upload.single()  — parses the multipart form and saves the file
// requirePhoto     — rejects the request if no file was included
router.post(
  '/registration',
  upload.single('profile_picture'),
  requirePhoto,
  asyncHandler(async (req, res) => {
    const profilePicturePath = path
      .join('uploads', 'profile_pictures', req.file.filename)
      .replace(/\\/g, '/');

    const result = await UserModel.createRegistration({
      ...req.body,
      profile_picture: profilePicturePath,
    });

    res.status(201).json({
      success: true,
      message: 'Registration application submitted successfully',
      data: result,
    });
  })
);

/* ===================== REGISTRATION PAYMENT ===================== */

router.post(
  '/payments/create-payment-intent',
  asyncHandler(async (req, res) => {
    const { amount, applicationId } = req.body;
    const result = await PaymentService.createPaymentIntent(amount, applicationId);
    res.json({ success: true, data: result });
  })
);

router.post(
  '/payments/record-payment',
  validateRequired(['applicationId', 'amount']),
  asyncHandler(async (req, res) => {
    const { applicationId, paymentIntentId, amount, paymentMethod = 'Card' } = req.body;
    const result = await PaymentService.recordPayment({
      applicationId,
      paymentIntentId,
      amount,
      paymentMethod,
    });
    res.json({ success: true, data: result });
  })
);

module.exports = router;