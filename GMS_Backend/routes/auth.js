const express = require('express');
const router = express.Router();

const UserModel = require('../models/User');
const AuthUtils = require('../utils/auth');

/* ========= HELPERS ========= */

const requireCredentials = (email, password) => {
  if (!email || !password) {
    throw new Error('Email and password are required');
  }
};

const loginHandler = (findMethod, userType) => async (req, res) => {
  try {
    const { email, password } = req.body;
    requireCredentials(email, password);

    const user = await UserModel[findMethod](email);
    const pass = await UserModel.verifyPassword(password, user.password);
    if (!user || !pass) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = AuthUtils.generateToken(user, userType);

    // Return token and user data
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        data: mapUser(user, userType)
      }
    });
  } catch (error) {
    res.status(400).json({ message: error.message || 'Login failed' });
  }
};

const mapUser = (user, userType) => {
  if (userType === 'member') {
    return {
      member_id: user.member_id,
      id: user.member_id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      address: user.address,
      userType: 'member',
      user: {
        id: user.member_id,
        name: user.name,
        email: user.email
      }
    };
  } else if (userType === 'staff') {
    return {
      user: {
        id: user.staff_id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    };
  } else if (userType === 'admin') {
    return {
      user: {
        id: user.admin_id,
        name: user.name,
        email: user.email,
        role: 'admin'
      }
    };
  }
};

/* ========= MEMBER LOGIN ========= */

router.post('/login', loginHandler('findMemberByEmail', 'member'));

/* ========= STAFF LOGIN =========## */

router.post('/staff/login', loginHandler('findStaffByEmail', 'staff'));

/* ========= ADMIN LOGIN =========## */

router.post('/admin/login', loginHandler('findAdminByEmail', 'admin'));

module.exports = router;
