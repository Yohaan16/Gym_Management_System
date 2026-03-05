const db = require('../config/database');
const bcrypt = require('bcrypt');
const config = require('../config/config');
const { parseDateToSql, isValidEmail, isValidPassword, getCurrentDate } = require('../utils/validators');
const { ValidationError, AuthenticationError, NotFoundError } = require('../utils/errorHandler');

class UserModel {
  /**
   * Create a new registration application
   */
  static async createRegistration(data) {
    const { name, email, phone, gender, dateOfBirth, address, password } = data;

    // Validate input
    if (!name || !email || !phone || !gender || !dateOfBirth || !address || !password) {
      throw new ValidationError('All fields are required');
    }

    if (!isValidEmail(email)) {
      throw new ValidationError('Invalid email format');
    }

    if (!isValidPassword(password)) {
      throw new ValidationError(`Password must be at least ${config.SECURITY.minPasswordLength} characters`);
    }

    // Parse date
    const dobSql = parseDateToSql(dateOfBirth);
    if (!dobSql) {
      throw new ValidationError('Invalid dateOfBirth format. Use DD/MM/YYYY or YYYY-MM-DD');
    }

    // Check if email exists
    const existingUser = await this.findByEmail(email);
    if (existingUser) {
      throw new ValidationError('Email already registered');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, config.SECURITY.bcryptRounds);
    const applicationDate = getCurrentDate();

    // Insert into database
    const sql = `
      INSERT INTO registration_application
      (name, email, phone, gender, dateOfBirth, address, password, application_date, payment)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending')
    `;

    const result = await db.query(sql, [name, email, phone, gender, dobSql, address, hashedPassword, applicationDate]);

    return {
      application_id: result.insertId,
      name,
      email,
      phone,
      gender,
      dateOfBirth: dobSql,
      address,
      payment: 'Pending'
    };
  }

  /**
   * Find user by email in member table (for login)
   */
  static async findMemberByEmail(email) {
    const sql = 'SELECT * FROM member WHERE email = ?';
    const users = await db.query(sql, [email]);
    return users[0] || null;
  }

  /**
   * Find staff by email (for staff login)
   */
  static async findStaffByEmail(email) {
    const sql = 'SELECT * FROM staff WHERE email = ?';
    const results = await db.query(sql, [email]);
    return results.length > 0 ? results[0] : null;
  }

  /**
   * Find admin by email (for admin login)
   */
  static async findAdminByEmail(email) {
    const sql = 'SELECT * FROM admin WHERE email = ?';
    const results = await db.query(sql, [email]);
    return results.length > 0 ? results[0] : null;
  }

  /**
   * Find user by email in registration applications
   */
  static async findByEmail(email) {
    const sql = 'SELECT * FROM registration_application WHERE email = ?';
    const users = await db.query(sql, [email]);
    return users[0] || null;
  }

  /**
   * Verify user password
   */
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Get all registration applications (exclude those already confirmed as members)
   */
  static async getAllRegistrations() {
    const sql = `
      SELECT ra.application_id, ra.name, ra.email, ra.phone, ra.gender, ra.dateOfBirth, ra.address, ra.application_date, ra.payment
      FROM registration_application ra
      LEFT JOIN member m ON ra.email = m.email
      WHERE m.member_id IS NULL
    `;
    return await db.query(sql);
  }

  /**
   * Approve a registration (mark for payment, don't create member yet)
   */
  static async approveRegistration(applicationId) {
    // Update registration payment status to Approved
    const updateSql = 'UPDATE registration_application SET payment = ? WHERE application_id = ?';
    await db.query(updateSql, ['Approved', applicationId]);

    return true;
  }

  /**
   * Confirm registration (create member account from approved registration)
   */
  static async confirmRegistration(applicationId) {
    // First, get the registration data
    const registrationSql = 'SELECT * FROM registration_application WHERE application_id = ?';
    const registrations = await db.query(registrationSql, [applicationId]);

    if (registrations.length === 0) {
      throw new NotFoundError('Registration');
    }

    const registration = registrations[0];

    // Check if already approved
    if (registration.payment !== 'Approved') {
      throw new ValidationError('Registration must be approved for payment first');
    }

    // Create member record
    const memberSql = `
      INSERT INTO member (name, email, phone, gender, dateOfBirth, address, password)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const result = await db.query(memberSql, [
      registration.name,
      registration.email,
      registration.phone,
      registration.gender,
      registration.dateOfBirth,
      registration.address,
      registration.password // Already hashed
    ]);

    const memberId = result.insertId;

    // Insert default membership (normal plan) for the new member
    try {
      const MembershipModel = require('./Membership');
      await MembershipModel.renewMembership(memberId, 'normal plan');
      const membership = await MembershipModel.getCurrentMembership(memberId);

      // Return member and membership info
      return {
        success: true,
        message: 'Member account created successfully',
        memberId,
        membership: membership || null
      };
    } catch (err) {
      return { success: true, message: 'Member account created successfully (membership creation failed)', memberId };
    }
  }

}

module.exports = UserModel;