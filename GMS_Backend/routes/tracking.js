const express = require('express');
const router = express.Router();
const DailyTracking = require('../models/DailyTracking');
const GoalModel = require('../models/Goal');

// Update daily tracking data
router.post('/update', async (req, res) => {
  try {
    const { member_id, calories_intake, calories_burnt, steps, water_consumed } = req.body;

    if (!member_id) {
      return res.status(400).json({ error: 'member_id is required' });
    }

    const trackingData = {
      calories_intake: calories_intake || 0,
      calories_burnt: calories_burnt || 0,
      steps: steps || 0,
      water_consumed: water_consumed || 0,
    };

    const result = await DailyTracking.updateDailyTracking(parseInt(member_id), trackingData);
    res.status(200).json(result);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get tracking history for a member
router.get('/history/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { days = 7 } = req.query;

    const history = await DailyTracking.getTrackingHistory(parseInt(memberId), parseInt(days));
    res.json(history);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get daily goals for a member
router.get('/goals/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const goals = await GoalModel.getGoalsByMember(parseInt(memberId));
    res.json(goals);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Set or update a daily goal
router.post('/goal', async (req, res) => {
  try {
    const { member_id, goal_type, target_value } = req.body;

    if (!member_id || !goal_type || target_value === undefined) {
      return res.status(400).json({ error: 'member_id, goal_type, and target_value are required' });
    }

    const goalId = await GoalModel.setGoal({
      member_id: parseInt(member_id),
      goal_type,
      target_value: parseFloat(target_value)
    });

    res.status(201).json({
      message: 'Goal set successfully',
      goal_id: goalId
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;