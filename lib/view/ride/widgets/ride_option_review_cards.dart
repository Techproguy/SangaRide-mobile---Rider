import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOptionRouteCard extends StatelessWidget {
  const RideOptionRouteCard({super.key, required this.pickup, required this.stops, required this.dropoff});

  final Place? pickup;
  final List<Place> stops;
  final Place? dropoff;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            spacing: SangaSpacing.md,
            children: [
              if (pickup != null) _RoutePoint(kind: SangaStopKind.pickup, place: pickup!),
              for (final stop in stops) _RoutePoint(kind: SangaStopKind.stop, place: stop),
              if (dropoff != null) _RoutePoint(kind: SangaStopKind.dropoff, place: dropoff!),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.kind, required this.place});

  final SangaStopKind kind;
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: SangaSpacing.sm,
      children: [
        SangaStopPin(kind),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
              Text(place.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.tileSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
