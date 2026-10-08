import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideDetailsCard extends StatelessWidget {
  const RideDetailsCard({super.key, required this.trip});

  final SafetyTrip trip;

  String get _startedAt => DateFormat('h:mm a').format(trip.startedAt);

  @override
  Widget build(BuildContext context) {
    final currentArea = trip.currentArea;
    return SangaDetailList(
      title: 'Ride details',
      trailing: trip.isLive
          ? const Padding(
              padding: EdgeInsets.only(right: SangaSpacing.xs),
              child: SangaTag.live(),
            )
          : null,
      rows: [
        SangaDetailRow(
          icon: Icons.person_outline_rounded,
          label: trip.counterpartRole.label,
          value: trip.counterpartName,
        ),
        SangaDetailRow(icon: Icons.directions_car_outlined, label: 'Vehicle', value: trip.vehicle),
        SangaDetailRow(icon: Icons.confirmation_number_outlined, label: 'Trip ID', value: trip.reference),
        SangaDetailRow(icon: Icons.trip_origin_rounded, label: 'Pickup', value: trip.pickup),
        SangaDetailRow(icon: Icons.location_on_outlined, label: 'Drop off', value: trip.dropoff),
        if (currentArea != null)
          SangaDetailRow(icon: Icons.near_me_outlined, label: 'Current route', value: currentArea),
        SangaDetailRow(icon: Icons.schedule_rounded, label: 'Started', value: _startedAt),
      ],
    );
  }
}
