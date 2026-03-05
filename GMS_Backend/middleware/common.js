const { handleError } = require('../utils/errorHandler');

/**
 * Request logging middleware
 */
function requestLogger(req, next) {
  console.log(`REQUEST: ${req.method} ${req.path} - Body:`, req.body);
  next();
}

/**
 * Response logging middleware
 */
function responseLogger(req, res, next) {
  const originalSend = res.send;
  res.send = function(data) {
    console.log(`RESPONSE: ${req.method} ${req.path} - Status: ${res.statusCode}`);
    originalSend.call(this, data);
  };
  next();
}

function validateRequired(requiredFields) {
  return (req, res, next) => {
    const missingFields = requiredFields.filter(field => !req.body[field]);

    if (missingFields.length > 0) {
      return res.status(400).json({
        error: 'Missing required fields',
        fields: missingFields
      });
    }

    next();
  };
}

/**
 * General error handling middleware
 */
function errorHandler(err, res) {
  handleError(err, res);
}

module.exports = {
  requestLogger,
  responseLogger,
  validateRequired,
  errorHandler
};