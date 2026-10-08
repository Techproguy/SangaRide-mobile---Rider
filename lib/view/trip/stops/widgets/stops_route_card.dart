import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class StopsRouteEntry {
  const StopsRouteEntry({required this.kind, required this.label, required this.value, this.onRemove});

  factory StopsRouteEntry.start(Trip trip) => trip.status == TripStatus.inProgress
      ? const StopsRouteEntry(kind: SangaStopKind.pickup, label: 'Current location', value: 'Where your driver is now')
      : StopsRouteEntry(kind: SangaStopKind.pickup, label: 'Pickup location', value: trip.pickup.name);

  static List<StopsRouteEntry> of(Trip trip, List<Place> added, {required ValueChanged<int> onRemove}) {
    return [
      StopsRouteEntry.start(trip),
      for (final (index, stop) in trip.stops.indexed)
        StopsRouteEntry(
          kind: SangaStopKind.stop,
          label: stop.isReached ? 'Stop ${index + 1} · Reached' : 'Stop ${index + 1}',
          value: stop.name,
        ),
      for (final (index, place) in added.indexed)
        StopsRouteEntry(
          kind: SangaStopKind.stop,
          label: 'Stop ${trip.stops.length + index + 1}',
          value: place.name,
          onRemove: () => onRemove(index),
        ),
      StopsRouteEntry(kind: SangaStopKind.dropoff, label: 'Drop off location', value: trip.dropoff.name),
    ];
  }

  final SangaStopKind kind;
  final String label;
  final String value;
  final VoidCallback? onRemove;
}

class StopsRouteCard extends StatelessWidget {
  const StopsRouteCard({super.key, required this.entries});

  final List<StopsRouteEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, entry) in entries.indexed)
                _StopsRouteRow(entry: entry, isLast: index == entries.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _StopsRouteRow extends StatelessWidget {
  const _StopsRouteRow({required this.entry, required this.isLast});

  final StopsRouteEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.sm,
        children: [
          Column(
            children: [
              SangaStopPin(entry.kind, size: 20),
              if (!isLast)
                const Expanded(
                  child: SizedBox(width: 1, child: ColoredBox(color: SangaColors.divider)),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : SangaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(entry.label, style: SangaTextStyles.cardSubtitle),
                  Text(entry.value, style: SangaTextStyles.cardTitle),
                ],
              ),
            ),
          ),
          if (entry.onRemove != null)
            IconButton(
              tooltip: 'Remove stop',
              visualDensity: VisualDensity.compact,
              onPressed: entry.onRemove,
              icon: const SangaIcon(SangaAssets.close, size: 14),
            ),
        ],
      ),
    );
  }
}
