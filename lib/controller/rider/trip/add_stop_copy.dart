abstract final class AddStopCopy {
  static const String unplaceable = 'We couldn’t place that stop. Try another one.';
  static const String sameAsPickup = 'Your stop can’t be the same as your pickup.';
  static const String sameAsDropoff = 'Your stop can’t be the same as your drop off.';
  static const String alreadyOnTrip = 'That place is already on your trip.';

  static String stopLimit(int maxStops) => 'You can add up to $maxStops stops.';
}
