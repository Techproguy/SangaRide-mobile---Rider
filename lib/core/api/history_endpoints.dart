abstract final class HistoryEndpoints {
  static const String rides = '/rides/history';
  static const String rideById = '/rides/history/:id';
  static const String blockDriver = '/drivers/:id/block';

  static String rideOf(String id) => rideById.replaceFirst(':id', id);

  static String blockDriverOf(String id) => blockDriver.replaceFirst(':id', id);
}
