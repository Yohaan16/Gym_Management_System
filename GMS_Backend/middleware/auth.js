const AuthUtils = require('../utils/auth');
const { AuthenticationError } = require('../utils/errorHandler');

// Verify JWT token middleware
const verifyJWT = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = AuthUtils.extractToken(authHeader);
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const decoded = AuthUtils.verifyToken(token);
    req.user = decoded;
    next();
  } catch (error) {
    if (error instanceof AuthenticationError) {
      return res.status(401).json({ message: error.message });
    }
    res.status(401).json({ message: 'Authentication failed' });
  }
};

// Require specific role middleware
const requireRole = (allowedRoles) => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: 'User not authenticated' });
      }

      const userRole = req.user.userType || req.user.role;
      
      if (!allowedRoles.includes(userRole)) {
        return res.status(403).json({ message: 'Access denied. Required role: ' + allowedRoles.join(', ') });
      }

      next();
    } catch (error) {
      res.status(403).json({ message: 'Authorization failed' });
    }
  };
};

module.exports = {
  verifyJWT,
  requireRole
};
