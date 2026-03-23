const db = require('../config/database');
const { ValidationError, NotFoundError } = require('../utils/errorHandler');

class PaymentModel {

  /* ========= HELPERS ========= */

  static normalizeId(value) {
    return value === 'null' || value === '' ? null : value;
  }

  static async getRegistration(applicationId, paymentStatus = null) {
    const sql = `
      SELECT * FROM registration_application
      WHERE application_id = ?
      ${paymentStatus ? 'AND payment = ?' : ''}
      LIMIT 1
    `;
    const rows = await db.query(sql, paymentStatus ? [applicationId, paymentStatus] : [applicationId]);
    if (!rows.length) throw new NotFoundError('Registration');
    return rows[0];
  }

  /* ========= PAYMENTS ========= */

  static async recordPayment({
    paymentSource = 'registration payment',
    memberId,
    applicationId,
    amount,
    paymentMethod,
    paymentIntentId = null
  }) {
    if (!amount) throw new ValidationError('Amount is required');

    const result = await db.query(
      `INSERT INTO payment (payment_source, member_id, application_id, amount, payment_method, payment_intent_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        paymentSource,
        this.normalizeId(memberId),
        this.normalizeId(applicationId),
        amount,
        paymentMethod,
        paymentIntentId
      ]
    );
    return result.insertId;
  }

  static recordCashPayment(applicationId, amount) {
    return this.recordPayment({ applicationId, amount, paymentMethod: 'Cash' });
  }

  /* ========= REGISTRATION ========= */

  static async updateRegistrationPaymentStatus(applicationId, payment = 'Approved') {
    const { affectedRows } = await db.query(
      `UPDATE registration_application SET payment = ? WHERE application_id = ?`,
      [payment, applicationId]
    );
    if (!affectedRows) throw new NotFoundError('Registration application');
  }

  /* ========= REPORTS ========= */

  static async getMonthlyRevenue(year = null) {
    const finalYear = year || new Date().getFullYear();
    return db.query(
      `SELECT payment_source,
              MONTH(payment_date) AS month,
              SUM(amount) AS total
       FROM payment
       WHERE YEAR(payment_date) = ?
       GROUP BY payment_source, MONTH(payment_date)
       ORDER BY month`,
      [finalYear]
    );
  }
}

module.exports = PaymentModel;