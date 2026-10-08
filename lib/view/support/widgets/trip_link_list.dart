import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/time_format.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripLinkList extends StatelessWidget {
  const TripLinkList({
    super.key,
    required this.rides,
    required this.selectedId,
    required this.onSelected,
    this.unknownTripId,
  });

  final List<HistoryItem> rides;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? unknownTripId;

  static String whenOf(DateTime time) => '${TimeFormat.date(time)}, ${TimeFormat.clock(time)}';

  @override
  Widget build(BuildContext context) {
    final unknown = unknownTripId;
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        if (unknown != null)
          SangaOptionCard(
            leading: const SangaIconBadge(size: 34, child: Icon(Icons.directions_car_outlined)),
            title: 'The trip you came from',
            isSelected: selectedId == unknown,
            onTap: () => onSelected(unknown),
          ),
        for (final ride in rides)
          SangaOptionCard(
            leading: SangaIconBadge(
              size: 34,
              child: Icon(ride.kind.isDelivery ? Icons.inventory_2_outlined : Icons.directions_car_outlined),
            ),
            title: '${ride.route.pickup.name} to ${ride.route.dropoff.name}',
            subtitle: whenOf(ride.occurredAt),
            isSelected: ride.id == selectedId,
            onTap: () => onSelected(ride.id),
          ),
        SangaOptionCard(
          leading: const SangaIconBadge(size: 34, child: Icon(Icons.not_interested_rounded)),
          title: 'Not about a trip',
          isSelected: selectedId == null,
          onTap: () => onSelected(null),
        ),
      ],
    );
  }
}
