// models/Notice.js
const db         = require('../config/database');
const FCMService = require('../services/FCMService');
const { ValidationError, NotFoundError } = require('../utils/errorHandler');

class NoticeModel {

  /* ==========================
     HELPERS
  ========================== */

  static baseSelect() {
    return `
      SELECT DISTINCT
        n.notice_id, n.staff_id, n.title, n.message, n.posted_date, n.target_type,
        s.name AS staff_name, s.email AS staff_email
      FROM notice n
      JOIN staff s ON n.staff_id = s.staff_id
    `;
  }

  static validate(title, message) {
    if (!title || !message || !title.trim() || !message.trim()) {
      throw new ValidationError('Title and message are required');
    }
    return { title: title.trim(), message: message.trim() };
  }

  /* ==========================
     CREATE
  ========================== */

  static async createNotice({
    staff_id, title, message, target_type = 'ALL', recipients = []
  }) {
    if (!staff_id) throw new ValidationError('Staff ID required');
    if (!['ALL', 'SELECTED'].includes(target_type))
      throw new ValidationError('Invalid target type');

    const data = this.validate(title, message);

    // ── Insert notice ────────────────────────────────────────────────────────
    const { insertId } = await db.query(
      `INSERT INTO notice (staff_id, title, message, target_type, posted_date)
       VALUES (?, ?, ?, ?, CURDATE())`,
      [staff_id, data.title, data.message, target_type]
    );

    // ── Insert recipients ────────────────────────────────────────────────────
    if (target_type === 'SELECTED' && recipients.length) {
      const rows        = recipients.map(memberId => [insertId, memberId]);
      const placeholders = rows.map(() => '(?, ?)').join(',');
      await db.query(
        `INSERT INTO notice_recipient (notice_id, member_id) VALUES ${placeholders}`,
        rows.flat()
      );
    }

    // ── Send push notifications (non-blocking) ───────────────────────────────
    // We fire-and-forget so a slow FCM response never delays the API response.
    this._sendPushNotifications({
      target_type,
      recipients,
      title: data.title,
      message: data.message,
      noticeId: insertId,
    }).catch(err =>
      console.error('[Notice] Push notification error:', err.message)
    );

    return { notice_id: insertId, ...data, target_type };
  }

  /* ==========================
     PUSH NOTIFICATIONS
  ========================== */

  /**
   * Fetches FCM tokens for the relevant members and sends push notifications.
   *
   * For target_type = 'ALL'      → fetches all member FCM tokens
   * For target_type = 'SELECTED' → fetches tokens only for specified recipients
   */
  static async _sendPushNotifications({
    target_type, recipients, title, message, noticeId,
  }) {
    let fcmTokens = [];

    if (target_type === 'ALL') {
      // Fetch all members who have an FCM token registered
      const rows = await db.query(
        `SELECT fcm_token FROM member WHERE fcm_token IS NOT NULL AND fcm_token != ''`
      );
      fcmTokens = rows.map(r => r.fcm_token);
    } else if (target_type === 'SELECTED' && recipients.length > 0) {
      // Fetch tokens only for the specified recipients
      const placeholders = recipients.map(() => '?').join(',');
      const rows = await db.query(
        `SELECT fcm_token FROM member
         WHERE member_id IN (${placeholders})
           AND fcm_token IS NOT NULL AND fcm_token != ''`,
        recipients
      );
      fcmTokens = rows.map(r => r.fcm_token);
    }

    if (fcmTokens.length === 0) {
      console.log('[Notice] No FCM tokens found for recipients — skipping push.');
      return;
    }

    // Truncate message body for notification preview (max 100 chars)
    const previewBody = message.length > 100
      ? `${message.substring(0, 97)}...`
      : message;

    await FCMService.sendToTokens(fcmTokens, title, previewBody, {
      notice_id: String(noticeId),
      type:      'notice',
    });
  }

  /* ==========================
     READ
  ========================== */

  static async getAllNotices(memberId = null) {
    let sql    = this.baseSelect();
    const params = [];

    if (memberId) {
      sql += `
        LEFT JOIN notice_recipient nr
          ON n.notice_id = nr.notice_id AND nr.member_id = ?
        WHERE n.target_type = 'ALL'
           OR (n.target_type = 'SELECTED' AND nr.member_id IS NOT NULL)
      `;
      params.push(memberId);
    } else {
      sql += ` WHERE n.target_type = 'ALL'`;
    }

    return db.query(
      `${sql} ORDER BY n.posted_date DESC, n.notice_id DESC LIMIT 10`,
      params
    );
  }

  static async getNoticeById(noticeId) {
    const [row] = await db.query(
      `${this.baseSelect()} WHERE n.notice_id = ? LIMIT 1`,
      [noticeId]
    );
    return row || null;
  }

  /* ==========================
     UPDATE
  ========================== */

  static async updateNotice(noticeId, data) {
    const { title, message } = this.validate(data.title, data.message);

    const res = await db.query(
      `UPDATE notice SET title = ?, message = ? WHERE notice_id = ?`,
      [title, message, noticeId]
    );

    if (!res.affectedRows) throw new NotFoundError('Notice');

    return { notice_id: noticeId, title, message };
  }

  /* ==========================
     DELETE
  ========================== */

  static async deleteNotice(noticeId) {
    const res = await db.query(
      `DELETE FROM notice WHERE notice_id = ?`,
      [noticeId]
    );
    if (!res.affectedRows) throw new NotFoundError('Notice');
    return { success: true };
  }

  /* ==========================
     RECIPIENTS
  ========================== */

  static async getNoticeRecipients(noticeId) {
    return db.query(
      `SELECT m.member_id, m.name, m.email
       FROM notice_recipient nr
       JOIN member m ON nr.member_id = m.member_id
       WHERE nr.notice_id = ?
       ORDER BY m.name`,
      [noticeId]
    );
  }
}

module.exports = NoticeModel;