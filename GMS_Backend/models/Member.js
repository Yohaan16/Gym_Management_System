const db = require('../config/database');
const bcrypt = require('bcrypt');
const config = require('../config/config');
const UserModel = require('./User');
const NoticeModel = require('./Notice');

class MemberModel {
  static async getAllWithMembership() {
    const sql = `
      SELECT 
        m.member_id,
        m.name,
        m.email,
        m.phone,
        m.gender,
        m.dateOfBirth,
        m.address,
        ms.membership_id,
        ms.start_date,
        ms.end_date,
        ms.membership_type,
        ms.status as membership_status
      FROM member m
      LEFT JOIN membership ms ON m.member_id = ms.member_id
      ORDER BY m.name ASC
    `;
    const rows = await db.query(sql);
    return rows;
  }

  static async getById(memberId) {
    const sql = `
      SELECT member_id, name, email, phone, gender, dateOfBirth, address, profile_picture
      FROM member
      WHERE member_id = ?
    `;
    const rows = await db.query(sql, [memberId]);
    return rows.length > 0 ? rows[0] : null;
  }

  static async update(memberId, data) {
    const { name, email, phone, gender, dateOfBirth, address } = data;
    const sql = 'UPDATE member SET name = ?, email = ?, phone = ?, gender = ?, dateOfBirth = ?, address = ? WHERE member_id = ?';
    const result = await db.query(sql, [name, email, phone, gender, dateOfBirth, address, memberId]);
    return result;
  }

  static async changePassword(memberId, currentPassword, newPassword) {
    const sql = 'SELECT password FROM member WHERE member_id = ?';
    const rows = await db.query(sql, [memberId]);

    if (rows.length === 0) {
      throw new Error('Member not found');
    }

    const hashedPassword = rows[0].password;

    const isValidPassword = await UserModel.verifyPassword(currentPassword, hashedPassword);
    if (!isValidPassword) {
      throw new Error('Current password is incorrect');
    }

    const newHashedPassword = await bcrypt.hash(newPassword, config.SECURITY.bcryptRounds);
    await db.query('UPDATE member SET password = ? WHERE member_id = ?', [newHashedPassword, memberId]);

    return { message: 'Password changed successfully' };
  }

  static async notifyMembershipRenewal(memberId, staffId) {
    const member = await this.getById(memberId);
    if (!member) {
      throw new Error('Member not found');
    }

    const membershipSql = `
      SELECT membership_type, end_date, status
      FROM membership
      WHERE member_id = ? AND status = 'active'
      ORDER BY end_date DESC
      LIMIT 1
    `;
    const membershipRows = await db.query(membershipSql, [memberId]);
    const membership = membershipRows.length > 0 ? membershipRows[0] : null;

    let message = `Dear ${member.name}, your membership renewal is due. `;
    if (membership) {
      const endDate = new Date(membership.end_date).toLocaleDateString();
      message += `Your ${membership.membership_type} membership expires on ${endDate}. `;
    }
    message += `Please renew your membership to continue enjoying our gym services. Contact reception for renewal options.`;

    const noticeData = {
      staff_id: staffId,
      title: 'Membership Renewal Reminder',
      message,
      posted_date: new Date().toISOString().split('T')[0],
      target_type: 'SELECTED',
      recipients: [memberId],
    };

    const result = await NoticeModel.createNotice(noticeData);

    return {
      message: 'Membership renewal notification sent successfully',
      notice_id: result.notice_id,
      member_name: member.name,
    };
  }
}

module.exports = MemberModel;