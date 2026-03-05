const express = require('express');
const UserModel = require('../models/User');
const { asyncHandler } = require('../utils/errorHandler');

const router = express.Router();

// Get all registration applications
router.get('/', asyncHandler(async (req, res) => {
  const applications = await UserModel.getAllRegistrations();
  res.json({ data: applications });
}));

// Get registration application by ID
router.get('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const application = await UserModel.getRegistrationById(id);

  if (!application) {
    return res.status(404).json({ error: 'Registration application not found' });
  }

  res.json(application);
}));

// Approve registration application
router.put('/:id/approve', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await UserModel.approveRegistration(id);
  res.json({ success: true, message: 'Application approved for payment' });
}));

// Confirm registration (create member account)
router.put('/:id/confirm', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await UserModel.confirmRegistration(id);
  res.json(result);
}));


module.exports = router;