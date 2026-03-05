const express = require('express');
const router = express.Router();
const MembershipModel = require('../models/Membership');
const PaymentService = require('../services/PaymentService');
const PaymentModel = require('../models/Payment');

const asyncHandler = fn => (req, res) =>
  fn(req, res).catch(err => {
    res.status(500).json({ error: err.message });
  });

/* =======================
   GET CURRENT MEMBERSHIP
======================= */
router.get('/:memberId', asyncHandler(async (req, res) => {
  const { memberId } = req.params;
  const membership = await MembershipModel.getCurrentMembership(parseInt(memberId));

  if (!membership) {
    return res.json({
      membership_type: 'None',
      status: 'inactive',
      days_remaining: 0
    });
  }

  res.json(membership);
}));

/* =======================
   CREATE PAYMENT INTENT
======================= */
router.post('/create-payment-intent', asyncHandler(async (req, res) => {
  const { member_id, membership_type, amount } = req.body;

  if (!member_id || !membership_type || !amount) {
    return res.status(400).json({ error: 'member_id, membership_type, and amount are required' });
  }

  const result = await PaymentService.createMembershipPaymentIntent(amount, member_id, membership_type);
  res.json(result);
}));

/* =======================
   CONFIRM MEMBERSHIP RENEWAL
======================= */
router.post('/confirm-renewal', asyncHandler(async (req, res) => {
  const { member_id, membership_type, paymentIntentId, amount, paymentMethod = 'Card' } = req.body;

  if (!member_id || !membership_type || !paymentIntentId) {
    return res.status(400).json({ error: 'member_id, membership_type, and paymentIntentId are required' });
  }

  const result = await PaymentService.recordMembershipPayment({
    memberId: parseInt(member_id),
    membershipType: membership_type,
    paymentIntentId,
    amount,
    paymentMethod
  });

  const updatedMembership = await MembershipModel.getCurrentMembership(parseInt(member_id));

  res.json({
    ...result,
    membership: updatedMembership || result.membership
  });
}));

/* =======================
   RENEW MEMBERSHIP ##
======================= */
router.post('/renew', asyncHandler(async (req, res) => {
  const { member_id, membership_type, amount, paymentMethod } = req.body;

  if (!member_id || !membership_type) {
    return res.status(400).json({ error: 'member_id and membership_type are required' });
  }

  // If a paymentMethod and amount are provided, record a payment row (Cash or Card)
  if (paymentMethod && amount) {
    const PaymentModel = require('../models/Payment');
    await PaymentModel.recordPayment({
      paymentSource: 'membership renewal',
      memberId: parseInt(member_id),
      applicationId: null,
      amount,
      paymentMethod
    });
  }

  const result = await MembershipModel.renewMembership(parseInt(member_id), membership_type);

  const updatedMembership = await MembershipModel.getCurrentMembership(parseInt(member_id));

  res.json({
    ...result,
    membership: updatedMembership
  });
}));

/* =======================
   CANCEL MEMBERSHIP ##
======================= */
router.put('/:memberId/cancel', asyncHandler(async (req, res) => {
  const { memberId } = req.params;
  await MembershipModel.cancelMembership(parseInt(memberId));
  res.json({ success: true, message: 'Membership cancelled successfully' });
}));

module.exports = router;