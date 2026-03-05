const express = require('express');
const router = express.Router();
const WorkoutModel = require('../models/Workout');

// Get workouts + goals for member (join)
router.get('/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const data = await WorkoutModel.getProgressForMember(parseInt(memberId));
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Increment workout counter (one set completed)
router.post('/increment', async (req, res) => {
  try {
    const { member_id, workout_type } = req.body;
    if (!member_id || !workout_type) {
      return res.status(400).json({ error: 'member_id and workout_type are required' });
    }

    await WorkoutModel.increment({ member_id: parseInt(member_id), workout_type });
    res.status(200).json({ message: 'Workout incremented' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Reset counters for a member
router.post('/reset/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    await WorkoutModel.resetForMember(parseInt(memberId));
    res.status(200).json({ message: 'Workout counters reset' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
