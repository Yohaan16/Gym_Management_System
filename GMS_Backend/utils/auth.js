const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { AuthenticationError} = require('./errorHandler');

class AuthUtils {
  
  static generateToken(user, userType) {
    const payload = {
      id: user.member_id || user.staff_id || user.admin_id,
      email: user.email,
      name: user.name,
      userType: userType
    };

    const token = jwt.sign(payload, config.SECURITY.jwtSecret, {
      expiresIn: config.SECURITY.jwtExpiration,
      algorithm: 'HS256'
    });

    return token;
  }

  static verifyToken(token) {
    try {
      if (!token) {
        throw new AuthenticationError('Token is missing');
      }

      const decoded = jwt.verify(token, config.SECURITY.jwtSecret, {
        algorithms: ['HS256']
      });

      return decoded;
    } catch (error) {
      if (error instanceof AuthenticationError) {
        throw error;
      }

      if (error.name === 'TokenExpiredError') {
        throw new AuthenticationError('Token has expired');
      } else if (error.name === 'JsonWebTokenError') {
        throw new AuthenticationError('Invalid token');
      }

      throw new AuthenticationError('Token verification failed: ' + error.message);
    }
  }

  static extractToken(authHeader) {
    if (!authHeader) return null;

    const parts = authHeader.split(' ');
    if (parts.length === 2 && parts[0].toLowerCase() === 'bearer') {
      return parts[1];
    }

    return null;
  }
}

module.exports = AuthUtils;
