import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaFareLine> rideFareLines({
  required FareEstimate estimate,
  required PricingOption pricing,
  required Money pricePerKm,
  required TripType tripType,
}) {
  final adjustment = estimate.adjustmentFor(pricing);
  return [
    if (estimate.baseFare.isPositive) SangaFareLine('Base fare', estimate.baseFare.format()),
    if (estimate.hasDistanceFare || estimate.hours != null || estimate.otherLines.isEmpty)
      _usageLine(estimate, pricePerKm, tripType),
    for (final line in estimate.otherLines) SangaFareLine(line.label, line.amount.format()),
    if (estimate.meetGreetFee case final fee? when fee.isPositive) SangaFareLine('Meet and greet', fee.format()),
    if (estimate.boost.isPositive) SangaFareLine('Demand boost', estimate.boost.format()),
    if (estimate.discount.isPositive) SangaFareLine('Discount', '-${estimate.discount.format()}'),
    if (pricing.adjustmentLabel case final label? when !adjustment.isZero)
      SangaFareLine(label, '${adjustment.isNegative ? '-' : '+'}${adjustment.abs().format()}'),
  ];
}

SangaFareLine _usageLine(FareEstimate estimate, Money pricePerKm, TripType tripType) {
  final hours = estimate.hours;
  final hourlyRate = estimate.hourlyRate;
  if (hours != null && hourlyRate != null) {
    final unit = hours == 1 ? 'hour' : 'hours';
    return SangaFareLine('$hours $unit at ${SangaMoney.perHourOf(hourlyRate)}', estimate.distanceFare.format());
  }
  final label = switch (tripType) {
    TripType.roundTrip => 'Round trip distance',
    TripType.intercity => 'Intercity distance',
    TripType.oneWay || TripType.hourly || TripType.airport || TripType.delivery => 'Distance',
  };
  return SangaFareLine(
    '$label (${SangaDistance.fromKilometers(estimate.distanceKm)} @ ${SangaMoney.perDistance(estimate.ratePerKm ?? pricePerKm)})',
    estimate.distanceFare.format(),
  );
}
