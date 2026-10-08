import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReceiptRouteCard extends StatelessWidget {
  const ReceiptRouteCard({super.key, required this.receipt});

  final TripReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.sm,
            children: [
              Expanded(
                child: SangaRouteSummary(
                  pickup: receipt.pickup.name,
                  dropoff: receipt.dropoff.name,
                  stops: [for (final stop in receipt.stops) stop.name],
                ),
              ),
              const SangaTag.success(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: SangaTripStats(
            stats: [
              SangaTripStat(Icons.route_outlined, receipt.distanceLabel),
              SangaTripStat(Icons.schedule_rounded, receipt.durationLabel),
            ],
          ),
        ),
      ],
    );
  }
}
