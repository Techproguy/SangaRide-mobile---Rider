import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class HistoryEndpoints {
  static const String rides = '/rides';
  static const String rideById = '/rides/:id';
  static const String blockedDrivers = '/rides/blocked-drivers';
  static const String blockedDriver = '/rides/blocked-drivers/:driverId';

  static String rideOf(String id) => fillPath(rideById, {'id': id});

  static String blockedDriverOf(String driverId) => fillPath(blockedDriver, {'driverId': driverId});
}
