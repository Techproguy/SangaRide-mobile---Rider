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
    if (estimate.baseFare case final fare? when fare.isPositive) SangaFareLine('Base fare', fare.format()),
    if (estimate.distanceFare != null &&
        (estimate.hasDistanceFare || estimate.hours != null || estimate.otherLines.isEmpty))
      _usageLine(estimate, estimate.distanceFare!, pricePerKm, tripType),
    for (final line in estimate.otherLines) SangaFareLine(line.label, line.amount.format()),
    if (estimate.meetGreetFee case final fee? when fee.isPositive) SangaFareLine('Meet and greet', fee.format()),
    if (estimate.boost case final boost? when boost.isPositive) SangaFareLine('Demand boost', boost.format()),
    if (estimate.discount case final discount? when discount.isPositive) SangaFareLine('Discount', '-${discount.format()}'),
    if (pricing.adjustmentLabel case final label? when !adjustment.isZero)
      SangaFareLine(label, '${adjustment.isNegative ? '-' : '+'}${adjustment.abs().format()}'),
  ];
}

SangaFareLine _usageLine(FareEstimate estimate, Money distanceFare, Money pricePerKm, TripType tripType) {
  final hours = estimate.hours;
  final hourlyRate = estimate.hourlyRate;
  if (hours != null && hourlyRate != null) {
    return SangaFareLine('${SangaPlural.count(hours, 'hour')} at ${SangaMoney.perHourOf(hourlyRate)}', distanceFare.format());
  }
  final label = switch (tripType) {
    TripType.roundTrip => 'Round trip distance',
    TripType.intercity => 'Intercity distance',
    TripType.oneWay || TripType.hourly || TripType.airport || TripType.delivery => 'Distance',
  };
  final distanceKm = estimate.distanceKm;
  if (distanceKm == null) return SangaFareLine(label, distanceFare.format());
  return SangaFareLine(
    '$label (${SangaDistance.fromKilometers(distanceKm)} @ ${SangaMoney.perDistance(estimate.ratePerKm ?? pricePerKm)})',
    distanceFare.format(),
  );
}
