import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class BookingEndpoints {
  static const String scheduledRides = '/rides/scheduled';
  static const String scheduledRide = '/rides/scheduled/:id';
  static const String scheduledRideReminder = '/rides/scheduled/:id/reminder';
  static const String hourlyRates = '/rides/hourly-rates';
  static const String cities = '/cities';
  static const String rules = '/rides/booking-rules';

  static String scheduledRideOf(String id) => fillPath(scheduledRide, {'id': id});

  static String scheduledRideReminderOf(String id) => fillPath(scheduledRideReminder, {'id': id});
}
