const express = require('express');
const NoticeModel = require('../models/Notice');
const { asyncHandler } = require('../utils/errorHandler');

const router = express.Router();

// Middleware to check staff role
const requireStaffRole = (req, res, next) => {
  if (!req.user || (req.user.role !== 'staff' && req.user.userType !== 'staff' && req.user.role !== 'admin')) {
    return res.status(403).json({ message: 'Staff authorization required' });
  }
  next();
};

// Create a new notice
router.post('/', requireStaffRole, asyncHandler(async (req, res) => {
  const { title, message, target_type = 'ALL', recipients = [] } = req.body;
  const staff_id = req.user.id; // From JWT token

  // Validate target_type
  if (!['ALL', 'SELECTED'].includes(target_type)) {
    return res.status(400).json({ message: 'Target type must be either ALL or SELECTED' });
  }

  // Validate recipients for SELECTED notices
  if (target_type === 'SELECTED') {
    if (!Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({ message: 'Recipients are required for SELECTED notices' });
    }
  }

  // Get current date
  const posted_date = new Date().toISOString().split('T')[0];

  const result = await NoticeModel.createNotice({
    staff_id,
    title,
    message,
    posted_date,
    target_type,
    recipients
  });

  res.status(201).json({
    message: 'Notice created successfully',
    data: result
  });
}));

// Get all notices
router.get('/', asyncHandler(async (req, res) => {
  const user = req.user; 
  
  let notices;

  // Check if user is a member 
  if (user.userType === 'member') {
    notices = await NoticeModel.getAllNotices(user.id);
  } else if (user.role === 'staff' || user.userType === 'staff' || user.role === 'admin') {
    notices = await NoticeModel.getAllNotices();
  } else {
    return res.status(401).json({ message: 'Authentication required' });
  }

  res.json({ data: notices });
}));

// Get notice by ID
router.get('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const user = req.user;
  const memberId = user.userType === 'member' ? user.id : null;

  const notice = await NoticeModel.getNoticeById(id, memberId);

  if (!notice) {
    return res.status(404).json({ message: 'Notice not found' });
  }

  // Check if member can access this notice
  if (memberId && notice.target_type === 'SELECTED') {
    const recipients = await NoticeModel.getNoticeRecipients(id);
    const isRecipient = recipients.some(r => r.member_id === memberId);
    if (!isRecipient) {
      return res.status(403).json({ message: 'Access denied' });
    }
  }

  res.json(notice);
}));

// Update notice
router.put('/:id', requireStaffRole, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { title, message } = req.body;
  const staff_id = req.user.id;

  const existingNotice = await NoticeModel.getNoticeById(id);
  if (!existingNotice) {
    return res.status(404).json({ message: 'Notice not found' });
  }

  if (existingNotice.staff_id !== staff_id) {
    return res.status(403).json({ message: 'You can only edit your own notices' });
  }

  const result = await NoticeModel.updateNotice(id, { title, message });

  res.json({
    message: 'Notice updated successfully',
    data: result
  });
}));

// Delete notice
router.delete('/:id', requireStaffRole, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const staff_id = req.user.id;

  const existingNotice = await NoticeModel.getNoticeById(id);
  if (!existingNotice) {
    return res.status(404).json({ message: 'Notice not found' });
  }

  if (existingNotice.staff_id !== staff_id) {
    return res.status(403).json({ message: 'You can only delete your own notices' });
  }

  const result = await NoticeModel.deleteNotice(id);

  res.json(result);
}));

module.exports = router;