const db = require('../config/database');

class ReviewModel {
  static async create(reviewData) {
    const { member_id, review_title, message, review_date } = reviewData;
    const sql = 'INSERT INTO review (member_id, review_title, message, review_date) VALUES (?, ?, ?, ?)';
    const result = await db.query(sql, [member_id, review_title, message, review_date]);
    return result.insertId;
  }

  static async getByMemberId(memberId) {
    const sql = 'SELECT review_id, member_id, review_title, message, review_date FROM review WHERE member_id = ? ORDER BY review_date DESC';
    const rows = await db.query(sql, [memberId]);
    return rows;
  }

  static async getAll() {
    const sql = 'SELECT r.review_id, r.member_id, r.review_title, r.message, r.review_date, r.sendAdmin, m.name as member_name FROM review r LEFT JOIN member m ON r.member_id = m.member_id ORDER BY r.review_date DESC';
    const rows = await db.query(sql);
    return rows;
  }

  static async delete(reviewId) {
    const sql = 'DELETE FROM review WHERE review_id = ?';
    await db.query(sql, [reviewId]);
    return { message: 'Review deleted successfully' };
  }

  static async updateSendAdmin(reviewId, sendAdmin) {
    const sql = 'UPDATE review SET sendAdmin = ? WHERE review_id = ?';
    await db.query(sql, [sendAdmin, reviewId]);
    return { message: 'Send to admin status updated successfully' };
  }
}

module.exports = ReviewModel;