import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum AirportEntry { pickUp, dropOff }

Future<void> openAirportRides(BuildContext context) async {
  final entry = await showSangaSheet<AirportEntry>(
    context: context,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.xl, SangaSpacing.gutter, SangaSpacing.md),
    builder: (context) => const _AirportEntrySheet(),
  );
  if (entry == null || !context.mounted) return;
  Get.find<RideForController>().reset();
  Get.find<AirportController>().begin();
  switch (entry) {
    case AirportEntry.pickUp:
      final ride = Get.find<RideRequestController>()..start();
      ride.setTripType(TripType.airport);
      await context.push(BookingRoutes.afterTripType(TripType.airport));
    case AirportEntry.dropOff:
      await context.push(BookingRoutes.airportDestination);
  }
}

class _AirportEntrySheet extends StatelessWidget {
  const _AirportEntrySheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        const Text('Airport rides', style: SangaTextStyles.title),
        SangaListGroup(
          children: [
            SangaListRow(
              leading: const SangaIconBadge(child: Icon(Icons.flight_land_rounded)),
              title: 'Pick me up from the airport',
              subtitle: 'Tell us your flight and we’ll time it for you',
              onTap: () => Navigator.of(context).pop(AirportEntry.pickUp),
            ),
            SangaListRow(
              leading: const SangaIconBadge(child: Icon(Icons.flight_takeoff_rounded)),
              title: 'Take me to the airport',
              subtitle: 'Pick your airport and book as usual',
              onTap: () => Navigator.of(context).pop(AirportEntry.dropOff),
            ),
          ],
        ),
      ],
    );
  }
}
