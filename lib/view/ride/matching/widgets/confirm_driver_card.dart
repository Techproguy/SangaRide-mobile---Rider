import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_stat_badge.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ConfirmDriverCard extends StatelessWidget {
  const ConfirmDriverCard({
    super.key,
    required this.hold,
    required this.pickup,
    required this.dropoff,
    required this.stops,
    required this.vehicleImage,
  });

  final DriverHold hold;
  final String pickup;
  final String dropoff;
  final List<String> stops;
  final ImageProvider vehicleImage;

  @override
  Widget build(BuildContext context) {
    final driver = hold.driver;
    final matchLabel = hold.matchLabel;
    final counter = hold.counterOffer;
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: SangaPersonHeader(
            name: driver.name,
            rating: driver.rating,
            photo: driver.photo,
            isVerified: driver.isVerified,
            caption: driver.ridesLabel,
            trailing: Row(
              spacing: SangaSpacing.sm,
              children: [
                DriverStatBadge(icon: Icons.alt_route_rounded, label: SangaDistance.away(hold.distanceAwayKm * 1000)),
                if (matchLabel != null)
                  DriverStatBadge(icon: Icons.done_all_rounded, label: matchLabel, tone: DriverStatTone.positive),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: SangaRouteSummary(pickup: pickup, dropoff: dropoff, stops: stops),
        ),
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            spacing: SangaSpacing.md,
            children: [
              SangaVehicleInfo(
                image: vehicleImage,
                lines: [
                  hold.vehicle.title,
                  hold.vehicle.colourLabel,
                  hold.vehicle.plateLabel,
                  if (hold.vehicle.features.isNotEmpty) hold.vehicle.features.join(', '),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fare ${SangaMoney.naira(hold.fare)}', style: SangaTextStyles.cardValue),
                  Text(
                    'Counter offer: ${counter == null ? 'none' : SangaMoney.naira(counter)}',
                    style: SangaTextStyles.cardValue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
