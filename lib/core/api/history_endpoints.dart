import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class HistoryEndpoints {
  static const String rides = '/rides/history';
  static const String rideById = '/rides/history/:id';
  static const String blockDriver = '/drivers/:id/block';

  static String rideOf(String id) => fillPath(rideById, {'id': id});

  static String blockDriverOf(String id) => fillPath(blockDriver, {'id': id});
}
