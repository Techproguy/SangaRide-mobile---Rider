import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/call_driver.dart';
import 'package:sanga_ride/view/trip/widgets/share_trip.dart';
import 'package:sanga_ride/view/trip/widgets/trip_contact_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_link_chip.dart';
import 'package:sanga_ride/view/trip/widgets/trip_progress_bar.dart';
import 'package:sanga_ride/view/trip/widgets/trip_timeline_link.dart';
import 'package:sanga_ride/view/trip/widgets/trip_vehicle_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();
    return Obx(() {
      final trip = controller.trip;
      return SangaPageLayout(
        title: 'Active ride details',
        children: [
          if (trip == null)
            const Padding(
              padding: EdgeInsets.all(SangaSpacing.xl),
              child: Center(child: SangaActivityIndicator(size: 40)),
            )
          else
            _Details(trip: trip, unreadCount: controller.unreadCount),
        ],
      );
    });
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.trip, required this.unreadCount});

  final Trip trip;
  final int unreadCount;

  static const EdgeInsets _cell = EdgeInsets.all(SangaSpacing.md);

  @override
  Widget build(BuildContext context) {
    final fare = trip.fare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        _group(context, fare),
        if (trip.canChange)
          SangaButton.danger(label: 'Cancel ride', onPressed: () => context.push(TripRoutes.cancelOf(trip.id))),
      ],
    );
  }

  Widget _group(BuildContext context, TripFare fare) {
    return SangaListGroup(
      children: [
        Padding(
          padding: _cell,
          child: TripDriverHeader(
            driver: trip.driver,
            trailing: TripLinkChip(label: 'View map', onPressed: context.pop),
          ),
        ),
        Padding(
          padding: _cell,
          child: SangaRouteSummary(
            pickup: trip.pickup.name,
            dropoff: trip.dropoff.name,
            stops: [for (final stop in trip.stops) stop.name],
          ),
        ),
        Padding(
          padding: _cell,
          child: Center(
            child: TripContactTiles(
              unreadCount: unreadCount,
              onCall: () => callDriver(context, firstName: trip.driver.firstName),
              onMessage: () => context.push(TripRoutes.chatOf(trip.id)),
              onShare: () => shareTrip(trip.id),
              onAddStops: trip.canAddStops ? () => context.push(TripRoutes.stopsOf(trip.id)) : null,
            ),
          ),
        ),
        Padding(
          padding: _cell,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fare ${SangaMoney.naira(fare.total)}', style: SangaTextStyles.cardValue),
              if (fare.counterOffer != null) Text('Counter offer accepted', style: SangaTextStyles.cardValue),
            ],
          ),
        ),
        Padding(
          padding: _cell,
          child: TripVehicleCard(trip: trip, showsFeatures: true),
        ),
        if (TripProgressBar.isShownFor(trip.status))
          Padding(
            padding: _cell,
            child: TripProgressBar(status: trip.status, nextStop: trip.nextStopNumber),
          ),
        Padding(
          padding: _cell,
          child: TripTimelineLink(onPressed: () => context.push(TripRoutes.timelineOf(trip.id))),
        ),
      ],
    );
  }
}
