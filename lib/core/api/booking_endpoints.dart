import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class BookingEndpoints {
  static const String scheduledRideCancel = '/rides/:id/cancel';
  static const String scheduledRideReminder = '/rides/:id/reminder';
  static const String series = '/rides/series';
  static const String seriesById = '/rides/series/:id';
  static const String hourlyTiers = '/ride-classes/:code/hourly-tiers';
  static const String cities = '/rides/intercity-cities';
  static const String rules = '/rides/booking-rules';

  static String hourlyTiersOf(String code) => fillPath(hourlyTiers, {'code': code});

  static String seriesOf(String id) => fillPath(seriesById, {'id': id});

  static String scheduledRideCancelOf(String id) => fillPath(scheduledRideCancel, {'id': id});

  static String scheduledRideReminderOf(String id) => fillPath(scheduledRideReminder, {'id': id});
}
