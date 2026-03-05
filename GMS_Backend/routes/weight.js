const express = require('express');
const router = express.Router();
const WeightModel = require('../models/Weight');
const GoalModel = require('../models/Goal');

// Add or update weight entry
router.post('/weight', async (req, res) => {
  try {
    const { member_id, weight, record_date } = req.body;

    if (!member_id || !weight || !record_date) {
      return res.status(400).json({ error: 'member_id, weight, and record_date are required' });
    }

    const weightId = await WeightModel.addWeight({
      member_id: parseInt(member_id),
      weight: parseFloat(weight),
      record_date
    });

    res.status(201).json({
      message: 'Weight recorded successfully',
      weight_id: weightId
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      res.status(409).json({ error: 'Weight already recorded for this date' });
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

// Get weight entries for a member
router.get('/weight/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const weights = await WeightModel.getWeights(parseInt(memberId));
    res.json(weights);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get latest weight for a member
router.get('/weight/:memberId/latest', async (req, res) => {
  try {
    const { memberId } = req.params;
    const latestWeight = await WeightModel.getLatestWeight(parseInt(memberId));
    res.json(latestWeight || { message: 'No weight records found' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Clear all weight entries for a member
router.delete('/weight/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    await WeightModel.clearWeights(parseInt(memberId));
    res.json({ message: 'All weight records cleared successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Set or update goal
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

// Get goal for a member
router.get('/goal/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const goal = await GoalModel.getGoal(parseInt(memberId));
    res.json(goal || { message: 'No goal set' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;