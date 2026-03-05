const BookingModel = require('../models/Booking');

class BookingService {
  static async bookClass(data) {
    const { paymentIntentId } = data;
    if (!paymentIntentId) {
      throw new Error('Payment confirmation required');
    }

    const bookingId = await BookingModel.createBooking(data);
    return {
      message: 'Class booked successfully',
      booking_id: bookingId
    };
  }
}

module.exports = {
  bookClass: BookingService.bookClass
};
