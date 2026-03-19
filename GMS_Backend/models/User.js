const db     = require('../config/database');
const bcrypt = require('bcrypt');
const config = require('../config/config');
const { parseDateToSql, isValidEmail, isValidPassword, getCurrentDate } = require('../utils/validators');
const { ValidationError, NotFoundError } = require('../utils/errorHandler');

class UserModel {

  // ===================== CREATE REGISTRATION =====================

  static async createRegistration(data) {
    const { name, email, phone, gender, dateOfBirth, address, password, profile_picture } = data;

    if (!name || !email || !phone || !gender || !dateOfBirth || !address || !password) {
      throw new ValidationError('All fields are required');
    }

    if (!isValidEmail(email)) {
      throw new ValidationError('Invalid email format');
    }

    if (!isValidPassword(password)) {
      throw new ValidationError(
        `Password must be at least ${config.SECURITY.minPasswordLength} characters`
      );
    }

    const dobSql = parseDateToSql(dateOfBirth);
    if (!dobSql) {
      throw new ValidationError('Invalid dateOfBirth format. Use DD/MM/YYYY or YYYY-MM-DD');
    }

    const existingUser = await this.findByEmail(email);
    if (existingUser) {
      throw new ValidationError('Email already registered');
    }

    // profile_picture is mandatory — enforced by the route middleware,
    // but we double-check here as a safety net.
    if (!profile_picture) {
      throw new ValidationError('A profile photo is required for registration');
    }

    const hashedPassword  = await bcrypt.hash(password, config.SECURITY.bcryptRounds);
    const applicationDate = getCurrentDate();

    const sql = `
      INSERT INTO registration_application
        (name, email, phone, gender, dateOfBirth, address, password, profile_picture,
         application_date, payment)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const result = await db.query(sql, [
      name, email, phone, gender, dobSql,
      address, hashedPassword, profile_picture, applicationDate, 'Pending',
    ]);

    return {
      application_id:  result.insertId,
      name,
      email,
      phone,
      gender,
      dateOfBirth:     dobSql,
      address,
      profile_picture,
      payment:         'Pending',
    };
  }

  // ===================== FIND HELPERS =====================

  static async findMemberByEmail(email) {
    const users = await db.query('SELECT * FROM member WHERE email = ?', [email]);
    return users[0] || null;
  }

  static async findStaffByEmail(email) {
    const results = await db.query('SELECT * FROM staff WHERE email = ?', [email]);
    return results.length > 0 ? results[0] : null;
  }

  static async findAdminByEmail(email) {
    const results = await db.query('SELECT * FROM admin WHERE email = ?', [email]);
    return results.length > 0 ? results[0] : null;
  }

  static async findByEmail(email) {
    const users = await db.query(
      'SELECT * FROM registration_application WHERE email = ?',
      [email]
    );
    return users[0] || null;
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  // ===================== GET ALL REGISTRATIONS =====================

  static async getAllRegistrations() {
    const sql = `
      SELECT ra.application_id, ra.name, ra.email, ra.phone, ra.gender,
             ra.dateOfBirth, ra.address, ra.application_date, ra.payment,
             ra.profile_picture
      FROM registration_application ra
      LEFT JOIN member m ON ra.email = m.email
      WHERE m.member_id IS NULL
    `;
    return await db.query(sql);
  }

  // ===================== APPROVE REGISTRATION =====================

  static async approveRegistration(applicationId) {
    await db.query(
      'UPDATE registration_application SET payment = ? WHERE application_id = ?',
      ['Approved', applicationId]
    );
    return true;
  }

  // ===================== CONFIRM REGISTRATION =====================

  static async confirmRegistration(applicationId) {
    const registrations = await db.query(
      'SELECT * FROM registration_application WHERE application_id = ?',
      [applicationId]
    );

    if (registrations.length === 0) throw new NotFoundError('Registration');

    const registration = registrations[0];

    if (registration.payment !== 'Approved') {
      throw new ValidationError('Registration must be approved for payment first');
    }

    // Copy profile_picture path into the member record
    const memberSql = `
      INSERT INTO member
        (name, email, phone, gender, dateOfBirth, address, password, profile_picture)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const result = await db.query(memberSql, [
      registration.name,
      registration.email,
      registration.phone,
      registration.gender,
      registration.dateOfBirth,
      registration.address,
      registration.password,       // Already hashed
      registration.profile_picture,
    ]);

    const memberId = result.insertId;

    try {
      const MembershipModel = require('./Membership');
      await MembershipModel.renewMembership(memberId, 'normal plan');
      const membership = await MembershipModel.getCurrentMembership(memberId);

      return {
        success:    true,
        message:    'Member account created successfully',
        memberId,
        membership: membership || null,
      };
    } catch (err) {
      return {
        success: true,
        message: 'Member account created successfully (membership creation failed)',
        memberId,
      };
    }
  }
}

module.exports = UserModel;