const db = require('../config/database');

class MembershipModel {
  static async getCurrentMembership(memberId) {
    const sql = `
      SELECT
        membership_id,
        membership_type,
        status,
        start_date,
        end_date,
        DATEDIFF(end_date, CURDATE()) AS days_remaining
      FROM membership
      WHERE member_id = ?
      AND status = 'active'
      ORDER BY end_date DESC
      LIMIT 1
    `;
    const rows = await db.query(sql, [memberId]);
    
    if (rows.length > 0) {
      const membership = rows[0];
      // Ensure days_remaining is a number
      membership.days_remaining = parseInt(membership.days_remaining) || 0;
      return membership;
    }
    
    return null;
  }

  static async renewMembership(memberId, membershipType) {
    const normalizedType = String(membershipType).toLowerCase().trim();
    
    const daysToAdd = normalizedType === 'normal plan' ? 30 : 365;

    const currentMembership = await db.query(
      "SELECT membership_id, end_date FROM membership WHERE member_id = ? AND (status = 'active' OR status = 'expired') ORDER BY end_date DESC LIMIT 1",
      [memberId]
    );

    if (currentMembership.length > 0) {

      const membershipId = currentMembership[0].membership_id;
      const currentEndDate = currentMembership[0].end_date;
  
      await db.query(
        `UPDATE membership
         SET start_date = IF(? > CURDATE(), ?, CURDATE()),
             end_date = DATE_ADD(IF(? > CURDATE(), ?, CURDATE()), INTERVAL ? DAY),
             membership_type = ?,
             status = 'active'
         WHERE membership_id = ?`,
        [currentEndDate, currentEndDate, currentEndDate, currentEndDate, daysToAdd, normalizedType, membershipId]
      );
    } else {
      await db.query(
        `INSERT INTO membership
         (member_id, start_date, end_date, status, membership_type)
         VALUES (?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY), 'active', ?)`,
        [memberId, daysToAdd, normalizedType]
      );
    }

    return { success: true, message: 'Membership renewed successfully' };
  }

  static async cancelMembership(memberId) {
    const sql = `
      UPDATE membership
      SET status = 'cancelled'
      WHERE member_id = ? AND status IN ('active', 'expired')
    `;
    await db.query(sql, [memberId]);
  }
}

module.exports = MembershipModel;