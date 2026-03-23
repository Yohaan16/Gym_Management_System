const express = require('express');
const router = express.Router();
const MemberModel = require('../models/Member');
const { asyncHandler } = require('../utils/errorHandler');
const db = require('../config/database');

// Staff authorization middleware
const requireStaffRole = (req, res, next) => {
  if (!req.user || (req.user.role !== 'staff' && req.user.userType !== 'staff' && req.user.role !== 'admin')) {
    return res.status(403).json({ message: 'Staff authorization required' });
  }
  next();
};

// Get all members with membership details ##
router.get('/retrieve', async (_req, res) => {
  try {
    const members = await MemberModel.getAllWithMembership();
    res.json(members);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get member details by ID
router.get('/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const member = await MemberModel.getById(parseInt(memberId));
    if (!member) {
      return res.status(404).json({ error: 'Member not found' });
    }
    res.json(member);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update member details
router.put('/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { name, email, phone, gender, dateOfBirth, address } = req.body;

    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }

    await MemberModel.update(parseInt(memberId), { name, email, phone: phone || '', gender: gender || '', dateOfBirth: dateOfBirth || '', address: address || '' });
    res.json({ message: 'Member updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Change member password
router.put('/:memberId/change-password', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { currentPassword, newPassword, confirmPassword } = req.body;

    if (!currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({ error: 'All password fields are required' });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ error: 'New password and confirmation do not match' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters long' });
    }

    const result = await MemberModel.changePassword(parseInt(memberId), currentPassword, newPassword);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generate short-lived QR token for member 
router.post('/:memberId/qr-token', async (req, res) => {
  try {
    const { memberId } = req.params;
    const member = await MemberModel.getById(parseInt(memberId));
    if (!member) return res.status(404).json({ error: 'Member not found' });

    const ttl = 120;

    const QRService = require('../services/QRService');
    const { token, expiresAt } = await QRService.generateToken(memberId, ttl);

    const qrPayload = token; 

    res.json({ token, qrPayload, expiresAt});
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Notify member about membership renewal (staff only) ##
router.post('/:memberId/notify-renewal', requireStaffRole, async (req, res) => {
  try {
    const { memberId } = req.params;
    const staffId = req.user.id; // From JWT token

    const result = await MemberModel.notifyMembershipRenewal(parseInt(memberId), staffId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/fcm-token', asyncHandler(async (req, res) => {
  const { member_id, fcm_token } = req.body;
 
  if (!member_id) {
    return res.status(400).json({ success: false, message: 'member_id is required' });
  }
 
  // fcm_token can be null (on logout) or a string (on login)
  await db.query(
    `UPDATE member SET fcm_token = ? WHERE member_id = ?`,
    [fcm_token ?? null, member_id]
  );
 
  res.json({
    success: true,
    message: fcm_token ? 'FCM token registered' : 'FCM token cleared',
  });
}));

module.exports = router;