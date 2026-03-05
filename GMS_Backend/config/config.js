require('dotenv').config();

module.exports = {
  // Server Configuration
  PORT: process.env.PORT,
  NODE_ENV: process.env.NODE_ENV,

  // Database Configuration
  DATABASE: {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT) || 10,
    queueLimit: 0
  },

  // Stripe Configuration
  STRIPE: {
    secretKey: process.env.STRIPE_SECRET_KEY,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET
  },

  // Security Configuration
  SECURITY: {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS) || 10,
    minPasswordLength: parseInt(process.env.MIN_PASSWORD_LENGTH) || 6,
    jwtSecret: process.env.JWT_SECRET ,
    jwtExpiration: process.env.JWT_EXPIRATION
  },

  // QR / short-lived token
  QR: {
    secret: process.env.QR_SECRET
  },

  // CORS Configuration
  CORS: {
    origin: process.env.CORS_ORIGIN,
    credentials: true
  }
};