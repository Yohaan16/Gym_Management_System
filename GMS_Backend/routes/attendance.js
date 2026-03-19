const express = require('express');
const router = express.Router();
const db = require('../config/database');
const AttendanceModel = require('../models/Attendance');
const MemberModel = require('../models/Member');
const QRService = require('../services/QRService');
let rateLimit;
try {
  rateLimit = require('express-rate-limit');
} catch (e) {
  rateLimit = (opts = {}) => (req, res, next) => next();
}

const asyncHandler = fn => (req, res) => fn(req, res).catch(err => res.status(500).json({ error: err.message }));

// Protect scan endpoint from rapid/repeated attempts (per-IP)
const scanLimiter = rateLimit({
  windowMs: 30 * 1000, // 30s
  max: 8, // allow up to 8 scans per window per IP
  standardHeaders: true,
  legacyHeaders: false,
});


router.get('/current', asyncHandler(async (_, res) => {
  const rows = await AttendanceModel.getCurrentlyIn();
  res.json(rows);
}));

router.get('/current/count', asyncHandler(async (_, res) => {
  const count = await AttendanceModel.getCurrentInCountForToday();
  res.json({ count });
}));

router.post('/scan', scanLimiter, asyncHandler(async (req, res) => {
  const token = req.body.token || req.body.qr;
  const staffId = req.user ? req.user.id : null; 

  if (!token) return res.status(400).json({ error: 'token_or_qr_required', message: 'Token or QR required' });

  const v = await QRService.verifyToken(token);
  if (!v.valid) {
    return res.status(400).json({ error: 'invalid_token', reason: v.reason, message: 'Invalid or expired QR' });
  }

  const payload = v.payload;
  const memberId = payload.memberId;

  const member = await MemberModel.getById(memberId);
  if (!member) {
    return res.status(404).json({ error: 'member_not_found', message: 'Member not found' });
  }

  // check membership active (best-effort)
  const [membership] = await db.query(
    `SELECT membership_id, status, end_date FROM membership WHERE member_id = ? AND status = 'active' ORDER BY end_date DESC LIMIT 1`,
    [memberId]
  );
  if (!membership) {
    return res.status(403).json({ error: 'membership_inactive', message: 'Membership inactive' });
  }

  const latest = await AttendanceModel.getLatestForMember(memberId);
  const nextStatus = (latest && latest.status === 'IN') ? 'OUT' : 'IN';

  // Insert attendance 
  try {
    await AttendanceModel.insert({ member_id: memberId, jti: payload.jti, status: nextStatus, scanned_by: staffId });
  } catch (err) {
    // Duplicate JTI 
    if (err && (err.code === 'ER_DUP_ENTRY' || err.errno === 1062)) {
      const existing = await AttendanceModel.getByJti(payload.jti).catch(() => null);
      return res.status(409).json({ error: 'duplicate_jti', existing, message: 'Duplicate scan' });
    }

    return res.status(500).json({ error: 'failed_to_record', message: 'Failed to record attendance' });
  }

  res.json({ action: nextStatus, member: { member_id: member.member_id, name: member.name, email: member.email }, message: `${member.name} checked ${nextStatus}` });
}));

module.exports = router;
