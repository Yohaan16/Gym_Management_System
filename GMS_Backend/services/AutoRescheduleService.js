const db           = require('../config/database');
const BookingModel = require('../models/Booking');
const NoticeModel  = require('../models/Notice');

// ── Configuration ─────────────────────────────────────────────────────────────
const MIN_CAPACITY    = 3;   
const HOURS_AHEAD     = 24;  
const SEARCH_DAYS     = 7;   
const SYSTEM_STAFF_ID = 1;   

// Scoring weights (must sum to 100)
const W_HISTORY   = 40;
const W_CAPACITY  = 25;
const W_PROXIMITY = 20;
const W_DAY_MATCH = 15;
// ─────────────────────────────────────────────────────────────────────────────

class AutoRescheduleService {

  static async run() {
    console.log('[AutoReschedule] Starting run at', new Date().toISOString());

    if (!db.isConnected) {
      console.log('[AutoReschedule] Initializing database...');
      await db.initialize();
    }

    const summary = { checked: 0, rescheduled: 0, skipped: 0, errors: [] };

    try {
      const slots = await this._getUnderAttendedSlots();
      summary.checked = slots.length;

      if (slots.length === 0) {
        console.log('[AutoReschedule] No under-attended slots found.');
        return summary;
      }

      for (const slot of slots) {
        const key = `${slot.class_id}|${slot.booking_date}|${slot.booking_time}`;
        try {
          const count = await this._processSlot(slot);
          summary.rescheduled += count;
          console.log(`[AutoReschedule] Slot ${key}: ${count} member(s) reassigned.`);
        } catch (err) {
          console.error(`[AutoReschedule] Failed to process slot ${key}:`, err.message);
          summary.errors.push({ slot: key, error: err.message });
          summary.skipped++;
        }
      }
    } catch (err) {
      console.error('[AutoReschedule] Fatal error:', err.message);
      summary.errors.push({ slot: 'global', error: err.message });
    }

    console.log('[AutoReschedule] Run complete:', summary);
    return summary;
  }

  static async rescheduleFromCancellation(
    classId, cancelDate, cancelTimeslot, affectedMembers
  ) {
    console.log(
      `[AutoReschedule] Staff cancellation reschedule: ` +
      `class ${classId}, ${cancelDate} ${cancelTimeslot}, ` +
      `${affectedMembers.length} member(s)`
    );

    if (affectedMembers.length === 0) {
      return { rescheduled: 0, failed: 0, results: [] };
    }

    // Build a synthetic slot object matching the shape _processSlot expects
    const slot = {
      class_id:     classId,
      booking_date: cancelDate,
      booking_time: cancelTimeslot,
      booking_count: affectedMembers.length,
      bookings:     affectedMembers,

      // Fetch class name for notifications
      class_name: await this._getClassName(classId),
    };

    const candidateSlots = await this._getCandidateSlots(slot);

    if (candidateSlots.length === 0) {
      console.warn(
        `[AutoReschedule] No candidate slots found for cancelled class ${classId} — ` +
        `members will need manual rebooking.`
      );
      return { rescheduled: 0, failed: affectedMembers.length, results: [] };
    }

    const costMatrix = await this._buildCostMatrix(
      affectedMembers, candidateSlots, slot
    );
    const assignment = this._hungarian(costMatrix);

    const results   = [];
    let rescheduled = 0;
    let failed      = 0;

    for (let i = 0; i < affectedMembers.length; i++) {
      const member       = affectedMembers[i];
      const candidateIdx = assignment[i];

      if (candidateIdx === -1 || candidateIdx >= candidateSlots.length) {
        console.warn(
          `[AutoReschedule] No valid slot for member ${member.member_id} ` +
          `after cancellation — skipping.`
        );
        failed++;
        results.push({ member_id: member.member_id, success: false, reason: 'No available slot' });
        continue;
      }

      const target = candidateSlots[candidateIdx];

      try {
        await BookingModel.rescheduleBooking({
          bookingId: member.booking_id,
          memberId:  member.member_id,
          classId,
          newDate:   target.date,
          newTime:   target.timeslot,
        });

        await this._notifyMember({
          memberId:   member.member_id,
          memberName: member.member_name,
          className:  slot.class_name,
          oldDate:    cancelDate,
          timeslot:   cancelTimeslot,
          newDate:    target.date,
          newTime:    target.timeslot,
          score:      costMatrix[i][candidateIdx],
          reason:     'staff_cancellation',
        });

        rescheduled++;
        results.push({
          member_id:  member.member_id,
          member_name: member.member_name,
          success:    true,
          newDate:    target.date,
          newTime:    target.timeslot,
          score:      costMatrix[i][candidateIdx],
        });

        console.log(
          `[AutoReschedule] Member ${member.member_id} rescheduled to ` +
          `${target.date} ${target.timeslot} (score: ${costMatrix[i][candidateIdx]})`
        );
      } catch (err) {
        console.error(
          `[AutoReschedule] Failed to reschedule member ${member.member_id}:`, err.message
        );
        failed++;
        results.push({
          member_id: member.member_id,
          success:   false,
          reason:    err.message,
        });
      }
    }

    console.log(
      `[AutoReschedule] Cancellation reschedule complete: ` +
      `${rescheduled} rescheduled, ${failed} failed.`
    );

    return { rescheduled, failed, results };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIND UNDER-ATTENDED SLOTS (cron only)
  // ══════════════════════════════════════════════════════════════════════════

  static async _getUnderAttendedSlots() {
    const sql = `
      SELECT
        b.class_id,
        DATE_FORMAT(b.booking_date, '%Y-%m-%d')   AS booking_date,
        b.booking_time,
        c.class_name,
        COUNT(*)                                   AS booking_count,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'booking_id',  b.booking_id,
            'member_id',   b.member_id,
            'member_name', m.name
          )
        )                                          AS bookings_json
      FROM booking b
      JOIN class  c ON b.class_id  = c.class_id
      JOIN member m ON b.member_id = m.member_id
      WHERE b.status = 'Confirmed'
        AND CAST(
              CONCAT(
                DATE_FORMAT(b.booking_date, '%Y-%m-%d'), ' ',
                SUBSTRING_INDEX(b.booking_time, ' - ', 1), ':00'
              ) AS DATETIME
            ) BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL ? HOUR)
      GROUP BY b.class_id, b.booking_date, b.booking_time, c.class_name
      HAVING booking_count < ?
      ORDER BY b.booking_date ASC, b.booking_time ASC
    `;

    const rows = await db.query(sql, [HOURS_AHEAD, MIN_CAPACITY]);

    return rows.map(row => ({
      class_id:      row.class_id,
      class_name:    row.class_name,
      booking_date:  row.booking_date,
      booking_time:  row.booking_time,
      booking_count: row.booking_count,
      bookings: typeof row.bookings_json === 'string'
        ? JSON.parse(row.bookings_json)
        : row.bookings_json,
    }));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROCESS A SINGLE UNDER-ATTENDED SLOT (cron only)
  // ══════════════════════════════════════════════════════════════════════════

  static async _processSlot(slot) {
    const members        = slot.bookings;
    const candidateSlots = await this._getCandidateSlots(slot);

    if (candidateSlots.length === 0) {
      console.warn(
        `[AutoReschedule] No candidate slots found for ${slot.class_name} — skipping.`
      );
      return 0;
    }

    console.log(
      `[AutoReschedule] ${slot.class_name} ${slot.booking_date} ${slot.booking_time}: ` +
      `${members.length} member(s), ${candidateSlots.length} candidate slot(s).`
    );

    const costMatrix = await this._buildCostMatrix(members, candidateSlots, slot);
    const assignment = this._hungarian(costMatrix);

    let rescheduled = 0;
    for (let i = 0; i < members.length; i++) {
      const member       = members[i];
      const candidateIdx = assignment[i];

      if (candidateIdx === -1 || candidateIdx >= candidateSlots.length) {
        console.warn(
          `[AutoReschedule] No valid slot found for member ${member.member_id} — skipping.`
        );
        continue;
      }

      const target = candidateSlots[candidateIdx];

      try {
        await BookingModel.rescheduleBooking({
          bookingId: member.booking_id,
          memberId:  member.member_id,
          classId:   slot.class_id,
          newDate:   target.date,
          newTime:   target.timeslot,
        });

        await this._notifyMember({
          memberId:   member.member_id,
          memberName: member.member_name,
          className:  slot.class_name,
          oldDate:    slot.booking_date,
          timeslot:   slot.booking_time,
          newDate:    target.date,
          newTime:    target.timeslot,
          score:      costMatrix[i][candidateIdx],
          reason:     'low_attendance',
        });

        rescheduled++;
      } catch (err) {
        console.error(
          `[AutoReschedule] Failed to reschedule member ${member.member_id}:`, err.message
        );
      }
    }

    return rescheduled;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERATE CANDIDATE SLOTS
  // ══════════════════════════════════════════════════════════════════════════

  static async _getCandidateSlots(slot) {
    const timeslotRows = await db.query(
      `SELECT DISTINCT booking_time
       FROM booking
       WHERE class_id = ? AND status = 'Confirmed'`,
      [slot.class_id]
    );
    const timeslots = timeslotRows.map(r => r.booking_time);

    const classRows = await db.query(
      'SELECT capacity FROM class WHERE class_id = ?',
      [slot.class_id]
    );
    const capacity = classRows[0]?.capacity ?? 10;

    const candidates = [];
    const today      = new Date();

    for (let d = 0; d <= SEARCH_DAYS; d++) {
      const date = new Date(today);
      date.setDate(today.getDate() + d);
      const dateStr = date.toISOString().split('T')[0];

      for (const timeslot of timeslots) {
        // Skip the original slot
        if (dateStr === slot.booking_date && timeslot === slot.booking_time) continue;

        // Skip cancelled slots
        const cancelled = await db.query(
          `SELECT cancel_id FROM cancel_class
           WHERE class_id = ? AND DATE(cancel_date) = ? AND cancel_timeslot = ?`,
          [slot.class_id, dateStr, timeslot]
        );
        if (cancelled.length > 0) continue;

        // Check current booking count
        const countRows = await db.query(
          `SELECT COUNT(*) AS count FROM booking
           WHERE class_id = ? AND booking_date = ? AND booking_time = ? AND status = 'Confirmed'`,
          [slot.class_id, dateStr, timeslot]
        );
        const currentCount = countRows[0]?.count ?? 0;
        if (currentCount >= capacity) continue;

        candidates.push({
          date:           dateStr,
          timeslot,
          currentCount,
          capacity,
          availableSpots: capacity - currentCount,
        });
      }
    }

    return candidates;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  COST MATRIX
  // ══════════════════════════════════════════════════════════════════════════

  static async _buildCostMatrix(members, candidateSlots, originalSlot) {
    const originalDate      = new Date(originalSlot.booking_date);
    const originalDayOfWeek = originalDate.getDay();

    const memberIds   = members.map(m => m.member_id);
    const historyRows = await db.query(
      `SELECT member_id, booking_time, COUNT(*) AS visit_count
       FROM booking
       WHERE member_id IN (${memberIds.map(() => '?').join(',')})
         AND class_id = ?
         AND status = 'Confirmed'
       GROUP BY member_id, booking_time`,
      [...memberIds, originalSlot.class_id]
    );

    const historyMap = {};
    for (const row of historyRows) {
      if (!historyMap[row.member_id]) historyMap[row.member_id] = {};
      historyMap[row.member_id][row.booking_time] = row.visit_count;
    }

    const allCounts = historyRows.map(r => r.visit_count);
    const maxVisits = allCounts.length > 0 ? Math.max(...allCounts) : 1;

    const matrix = [];

    for (const member of members) {
      const row        = [];
      const memberHist = historyMap[member.member_id] || {};

      for (const candidate of candidateSlots) {
        const candidateDate      = new Date(candidate.date);
        const daysAway           = Math.abs(
          (candidateDate - originalDate) / (1000 * 60 * 60 * 24)
        );
        const candidateDayOfWeek = candidateDate.getDay();

        const visits        = memberHist[candidate.timeslot] ?? 0;
        const historyScore  = (visits / maxVisits) * W_HISTORY;
        const capacityScore = (candidate.availableSpots / candidate.capacity) * W_CAPACITY;
        const proximityScore =
          (1 - Math.min(daysAway, SEARCH_DAYS) / SEARCH_DAYS) * W_PROXIMITY;
        const dayMatchScore =
          candidateDayOfWeek === originalDayOfWeek ? W_DAY_MATCH : 0;

        const totalScore =
          historyScore + capacityScore + proximityScore + dayMatchScore;

        row.push(Math.round(totalScore * 100) / 100);
      }

      matrix.push(row);
    }

    return matrix;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HUNGARIAN ALGORITHM
  // ══════════════════════════════════════════════════════════════════════════

  static _hungarian(scoreMatrix) {
    const rows = scoreMatrix.length;
    if (rows === 0) return [];

    const cols = scoreMatrix[0].length;
    if (cols === 0) return new Array(rows).fill(-1);

    const n    = Math.max(rows, cols);
    const cost = [];
    for (let i = 0; i < n; i++) {
      cost.push([]);
      for (let j = 0; j < n; j++) {
        cost[i][j] = i < rows && j < cols ? -scoreMatrix[i][j] : 0;
      }
    }

    const INF = Infinity;
    const u   = new Array(n + 1).fill(0);
    const v   = new Array(n + 1).fill(0);
    const p   = new Array(n + 1).fill(0);
    const way = new Array(n + 1).fill(0);

    for (let i = 1; i <= n; i++) {
      p[0] = i;
      let j0 = 0;
      const minDist = new Array(n + 1).fill(INF);
      const used    = new Array(n + 1).fill(false);

      do {
        used[j0] = true;
        const i0 = p[j0];
        let delta = INF;
        let j1    = -1;

        for (let j = 1; j <= n; j++) {
          if (!used[j]) {
            const cur = cost[i0 - 1][j - 1] - u[i0] - v[j];
            if (cur < minDist[j]) {
              minDist[j] = cur;
              way[j]     = j0;
            }
            if (minDist[j] < delta) {
              delta = minDist[j];
              j1    = j;
            }
          }
        }

        for (let j = 0; j <= n; j++) {
          if (used[j]) {
            u[p[j]] += delta;
            v[j]    -= delta;
          } else {
            minDist[j] -= delta;
          }
        }

        j0 = j1;
      } while (p[j0] !== 0);

      do {
        p[j0] = p[way[j0]];
        j0    = way[j0];
      } while (j0);
    }

    const result = new Array(rows).fill(-1);
    for (let j = 1; j <= n; j++) {
      const assignedRow = p[j] - 1;
      if (assignedRow >= 0 && assignedRow < rows && j - 1 < cols) {
        result[assignedRow] = j - 1;
      }
    }

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFY MEMBER
  // ══════════════════════════════════════════════════════════════════════════

  static async _notifyMember({
    memberId, memberName, className,
    oldDate, timeslot, newDate, newTime, score, reason,
  }) {
    const isStaffCancellation = reason === 'staff_cancellation';

    const message = isStaffCancellation
      ? `Dear ${memberName},\n\n` +
        `Your ${className} class on ${oldDate} at ${timeslot} has been cancelled by staff.\n\n` +
        `We have automatically rescheduled your booking to the best available slot:\n` +
        `New slot: ${newDate} at ${newTime}\n\n` +
        `This slot was selected based on your booking history and preferences ` +
        `(match score: ${score}/100).\n\n` +
        `If this time does not suit you, you may cancel or reschedule your booking ` +
        `from the app at no charge.`
      : `Dear ${memberName},\n\n` +
        `Your ${className} class on ${oldDate} at ${timeslot} has been automatically ` +
        `rescheduled due to low attendance.\n\n` +
        `Your new slot: ${newDate} at ${newTime}\n\n` +
        `This slot was selected as your best available alternative ` +
        `based on your booking history and preferences (match score: ${score}/100).\n\n` +
        `If this time does not suit you, you may cancel or reschedule ` +
        `your booking from the app at no charge.`;

    try {
      await NoticeModel.createNotice({
        staff_id:    SYSTEM_STAFF_ID,
        title:       isStaffCancellation
          ? 'Class Cancelled — Automatically Rescheduled'
          : 'Class Automatically Rescheduled',
        message,
        posted_date: new Date().toISOString().split('T')[0],
        target_type: 'SELECTED',
        recipients:  [memberId],
      });
    } catch (err) {
      console.warn(
        `[AutoReschedule] Failed to notify member ${memberId}:`, err.message
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER — GET CLASS NAME
  // ══════════════════════════════════════════════════════════════════════════

  static async _getClassName(classId) {
    const rows = await db.query(
      'SELECT class_name FROM class WHERE class_id = ?',
      [classId]
    );
    return rows[0]?.class_name ?? 'Class';
  }
}

module.exports = AutoRescheduleService;