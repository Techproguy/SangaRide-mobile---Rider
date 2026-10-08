import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_eta_line.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryLiveStatus extends StatelessWidget {
  const DeliveryLiveStatus({super.key, required this.trip, required this.phase});

  final Trip trip;
  final DeliveryPhase phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: const BoxDecoration(color: SangaColors.chipBlue, borderRadius: SangaRadii.field),
      child: Row(
        spacing: SangaSpacing.sm,
        children: [
          const SangaTag.live(),
          Expanded(child: Text(phase.statusLine, style: SangaTextStyles.cardTitle)),
          if (phase.showsEta) TripEtaLine(etaAt: trip.etaAt, distanceRemainingKm: trip.distanceRemainingKm),
        ],
      ),
    );
  }
}
