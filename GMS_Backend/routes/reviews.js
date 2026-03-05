const express = require('express');
const router = express.Router();
const ReviewModel = require('../models/Review');

// Submit a review
router.post('/', async (req, res) => {
  try {
    const { member_id, review_title, message, review_date } = req.body;

    if (!member_id || !review_title || !message || !review_date) {
      return res.status(400).json({ error: 'member_id, review_title, message, and review_date are required' });
    }

    const reviewId = await ReviewModel.create({
      member_id,
      review_title,
      message,
      review_date
    });

    res.status(201).json({
      message: 'Review submitted successfully',
      review_id: reviewId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all reviews (for admin/staff)
router.get('/', async (req, res) => {
  try {
    const reviews = await ReviewModel.getAll();
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update send to admin status
router.put('/:reviewId/send-admin', async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { sendAdmin } = req.body;

    if (typeof sendAdmin !== 'boolean') {
      return res.status(400).json({ error: 'sendAdmin must be a boolean value' });
    }

    const result = await ReviewModel.updateSendAdmin(reviewId, sendAdmin);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;