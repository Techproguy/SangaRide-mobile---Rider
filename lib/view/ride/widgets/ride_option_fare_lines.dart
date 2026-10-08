import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaFareLine> rideFareLines({
  required FareEstimate estimate,
  required PricingOption pricing,
  required num pricePerKm,
  required TripType tripType,
}) {
  final adjustment = estimate.adjustmentFor(pricing);
  return [
    if (estimate.baseFare > 0) SangaFareLine('Base fare', SangaMoney.naira(estimate.baseFare)),
    _usageLine(estimate, pricePerKm, tripType),
    if (estimate.meetGreetFee case final fee? when fee > 0) SangaFareLine('Meet and greet', SangaMoney.naira(fee)),
    if (estimate.boost > 0) SangaFareLine('Demand boost', SangaMoney.naira(estimate.boost)),
    if (estimate.discount > 0) SangaFareLine('Discount', '-${SangaMoney.naira(estimate.discount)}'),
    if (pricing.adjustmentLabel case final label? when adjustment != 0)
      SangaFareLine(label, '${adjustment < 0 ? '-' : '+'}${SangaMoney.naira(adjustment.abs())}'),
  ];
}

SangaFareLine _usageLine(FareEstimate estimate, num pricePerKm, TripType tripType) {
  final hours = estimate.hours;
  final hourlyRate = estimate.hourlyRate;
  if (hours != null && hourlyRate != null) {
    final unit = hours == 1 ? 'hour' : 'hours';
    return SangaFareLine('$hours $unit at ${SangaMoney.perHour(hourlyRate)}', SangaMoney.naira(estimate.distanceFare));
  }
  final distance = estimate.distanceKm.toStringAsFixed(1);
  final label = switch (tripType) {
    TripType.roundTrip => 'Round trip distance',
    TripType.intercity => 'Intercity distance',
    TripType.oneWay || TripType.hourly || TripType.airport => 'Distance',
  };
  return SangaFareLine(
    '$label ($distance km @ ${SangaMoney.perKm(estimate.ratePerKm ?? pricePerKm)})',
    SangaMoney.naira(estimate.distanceFare),
  );
}
