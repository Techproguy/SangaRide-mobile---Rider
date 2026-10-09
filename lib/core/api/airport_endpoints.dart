import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class AirportEndpoints {
  static const String airports = '/airports';
  static const String airlines = '/airlines';
  static const String flightLookup = '/flights/lookup';
  static const String rideFlight = '/rides/:id/flight';
  static const String notifyDriver = '/rides/scheduled/:id/notify-driver';

  static String rideFlightOf(String id) => fillPath(rideFlight, {'id': id});

  static String notifyDriverOf(String id) => fillPath(notifyDriver, {'id': id});
}
