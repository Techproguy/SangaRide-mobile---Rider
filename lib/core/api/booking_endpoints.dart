abstract final class BookingEndpoints {
  static const String scheduledRides = '/rides/scheduled';
  static const String scheduledRide = '/rides/scheduled/:id';
  static const String scheduledRideReminder = '/rides/scheduled/:id/reminder';
  static const String hourlyRates = '/rides/hourly-rates';
  static const String cities = '/cities';

  static String scheduledRideOf(String id) => scheduledRide.replaceFirst(':id', id);

  static String scheduledRideReminderOf(String id) => scheduledRideReminder.replaceFirst(':id', id);
}
