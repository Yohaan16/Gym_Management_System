const StatsModel = require('../models/Stats');

class StatsService {
  static async getDashboardStats() {
    try {
      const totalMembers = await StatsModel.getTotalMembers();
      const newRegistrationsThisMonth = await StatsModel.getNewRegistrationsThisMonth();
      const membershipsCancelled = await StatsModel.getCancelledMemberships();
      const topClassOfMonth = await StatsModel.getTopClassOfMonth();
      const topClassesBooked = await StatsModel.getTopClassesBooked(5);
      const membersList = await StatsModel.getMembersList();
      const staffList = await StatsModel.getStaffList();
      return {
        totalMembers,
        newRegistrationsThisMonth,
        membershipsCancelled,
        topClassOfMonth,
        topClassesBooked,
        membersList,
        staffList
      };
    } catch (error) {
      throw error;
    }
  }

  static async getAttendanceSeries(days = 30) {
    try {
      const series = await StatsModel.getAttendanceSeries(days);
      return series;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = StatsService;