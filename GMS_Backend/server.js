const express = require('express');
const cors = require('cors');
const config = require('./config/config');
const { verifyJWT} = require('./middleware/auth');

// Import error handler
const { handleError } = require('./utils/errorHandler');
const authRoutes = require('./routes/auth');
const RegistrationRoutes = require('./routes/reg_application');
const bookingRoutes = require('./routes/booking');
const paymentRoutes = require('./routes/payment');
const weightRoutes = require('./routes/weight');
const trackingRoutes = require('./routes/tracking');
const workoutRoutes = require('./routes/workouts');
const memberRoutes = require('./routes/members');
const membershipRoutes = require('./routes/memberships');
const reviewRoutes = require('./routes/reviews');
const registrationRoutes = require('./routes/registrations');
const noticesRoutes = require('./routes/notices');
const attendanceRoutes = require('./routes/attendance');
const adminRoutes = require('./routes/admin');
require('./jobs/autoReschedule');

const app = express();

// Middleware
app.use(cors(config.CORS));
app.use(express.json());

// Serve static files from uploads directory
app.use('/uploads', express.static('uploads'));


// Initialize database
const db = require('./config/database');

// Routes (no auth required)
app.use('/api/auth', authRoutes);
app.use('/api/reg_application', RegistrationRoutes);

// Protected routes (require valid JWT)
app.use('/api/bookings', verifyJWT, bookingRoutes);
app.use('/api/payments', verifyJWT, paymentRoutes);
app.use('/api/weight', verifyJWT, weightRoutes);
app.use('/api/tracking', verifyJWT, trackingRoutes);
app.use('/api/workouts', verifyJWT, workoutRoutes);
app.use('/api/members', verifyJWT, memberRoutes);
app.use('/api/membership', verifyJWT, membershipRoutes);
app.use('/api/reviews', verifyJWT, reviewRoutes);
app.use('/api/registrations', verifyJWT, registrationRoutes);
app.use('/api/notices', verifyJWT, noticesRoutes);
app.use('/api/attendance', verifyJWT, attendanceRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error caught by error handler:', err);
  handleError(err, res);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
async function startServer() {
  try {
    // Initialize database
    await db.initialize();

    const PORT = config.PORT;
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Database: ${db.isConnected ? 'Connected' : 'Disconnected'}`);
      console.log(`Environment: ${config.NODE_ENV}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;