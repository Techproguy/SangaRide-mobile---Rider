import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaFareLine> rideFareLines({
  required FareEstimate estimate,
  required PricingOption pricing,
  required num pricePerKm,
  required bool isRoundTrip,
}) {
  final distance = estimate.distanceKm.toStringAsFixed(1);
  final adjustment = estimate.adjustmentFor(pricing);
  return [
    SangaFareLine('Base fare', SangaMoney.naira(estimate.baseFare)),
    SangaFareLine(
      '${isRoundTrip ? 'Round trip distance' : 'Distance'} ($distance km @ ${SangaMoney.perKm(pricePerKm)})',
      SangaMoney.naira(estimate.distanceFare),
    ),
    if (estimate.boost > 0) SangaFareLine('Demand boost', SangaMoney.naira(estimate.boost)),
    if (estimate.discount > 0) SangaFareLine('Discount', '-${SangaMoney.naira(estimate.discount)}'),
    if (pricing.adjustmentLabel case final label? when adjustment != 0)
      SangaFareLine(label, '${adjustment < 0 ? '-' : '+'}${SangaMoney.naira(adjustment.abs())}'),
  ];
}
