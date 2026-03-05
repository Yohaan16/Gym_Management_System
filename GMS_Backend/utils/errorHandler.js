class AppError extends Error {
  constructor(message, statusCode = 500, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message, details = null) {
    super(message, 400, details);
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Invalid credentials') {
    super(message, 401);
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404);
  }
}

/**
 * Handle errors and send appropriate response
 * @param {Error} error - Error object
 * @param {Object} res - Express response object
 */
function handleError(error, res) {
  console.error('Error:', error.message);

  if (error.isOperational) {
    return res.status(error.statusCode).json({
      error: error.message,
      ...(error.details && { details: error.details })
    });
  }

  // Programming or unknown error
  return res.status(500).json({
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
}

/**
 * Async error wrapper for route handlers
 * @param {Function} fn - Route handler function
 * @returns {Function} - Wrapped function
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  NotFoundError,
  handleError,
  asyncHandler
};