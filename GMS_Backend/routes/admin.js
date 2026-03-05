const express = require('express');
const router = express.Router();
const { verifyJWT, requireRole } = require('../middleware/auth');
const StatsService = require('../services/StatsService');
const PaymentService = require('../services/PaymentService');
const ReviewModel = require('../models/Review');

router.get('/stats', verifyJWT, async (req, res) => {
  try {
    const result = await StatsService.getDashboardStats();
    res.json({ data: result });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get(
  '/dashboard',
  verifyJWT,
  requireRole(['staff', 'admin']),
  async (req, res) => {
    try {
        // Get stats, topClasses, membersList, staffList
      let statsData = {};
      try {
        statsData = await StatsService.getDashboardStats();
      } catch (err) {
        statsData = {};
      }

      // Get payment summary
      let paymentSummary = [];
      try {
          paymentSummary = await PaymentService.getMonthlyRevenue();
      } catch (err) {
        paymentSummary = [];
      }

      // Get important queries (reviews sent to admin)
      let importantQueries = [];
      try {
        const allReviews = await ReviewModel.getAll();
        importantQueries = allReviews
          .filter((review) => review.sendAdmin === 1)
          .map((review) => ({
            title: review.review_title,
            date: new Date(review.review_date).toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric'
            }),
            member: review.member_name,
            message: review.message
          }))
          .slice(0, 4); // Latest 4
      } catch (err) {
        importantQueries = [];
      }

      // Fetch attendance series (last 30 days)
      let attendanceSeries = [];
      try {
        attendanceSeries = await StatsService.getAttendanceSeries(30);
      } catch (err) {
        attendanceSeries = [];
      }

      const result = {
        stats: {
          totalMembers: statsData.totalMembers,
          newRegistrationsThisMonth: statsData.newRegistrationsThisMonth,
          membershipsCancelled: statsData.membershipsCancelled,
          topClassOfMonth: statsData.topClassOfMonth
        },
        paymentSummary,
        topClassesBooked: statsData.topClassesBooked,
        membersList: statsData.membersList,
        staffList: statsData.staffList,
        importantQueries,
        attendanceSeries
      };

      res.json({ data: result });
    } catch (error) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

module.exports = router;
