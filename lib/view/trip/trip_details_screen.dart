import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/call_driver.dart';
import 'package:sanga_ride/view/trip/widgets/delivery_package_line.dart';
import 'package:sanga_ride/view/trip/widgets/delivery_progress_bar.dart';
import 'package:sanga_ride/view/trip/widgets/share_trip.dart';
import 'package:sanga_ride/view/trip/widgets/trip_action_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
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
    return TripPageGate(
      tripId: tripId,
      title: 'Active ride details',
      child: Obx(() {
        final trip = controller.trip;
        return SangaPageLayout(
          title: trip?.isDelivery == true ? 'Delivery details' : 'Active ride details',
          children: [
            if (trip == null)
              const SangaSkeleton.heights([120, 160, 90])
            else
              _Details(trip: trip, unreadCount: controller.unreadCount),
          ],
        );
      }),
    );
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
          SangaButton.danger(
            label: trip.isDelivery ? 'Cancel delivery' : 'Cancel ride',
            onPressed: () => context.push(TripRoutes.cancelOf(trip.id)),
          ),
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
        if (trip.delivery case final TripDelivery delivery) ..._deliverySections(context, delivery),
        Padding(
          padding: _cell,
          child: Center(
            child: TripActionTiles(
              unreadCount: unreadCount,
              onCall: () => callDriver(context, firstName: trip.driver.firstName),
              onMessage: () => context.push(TripRoutes.chatOf(trip.id)),
              onShare: () => shareTrip(trip.id, isDelivery: trip.isDelivery),
              onSafety: trip.isDelivery ? () => context.push(SafetyRoutes.centreOf(tripId: trip.id)) : null,
              onAddStops: trip.canAddStops ? () => context.push(TripRoutes.stopsOf(trip.id)) : null,
              onReportIssue: trip.isDelivery ? () => context.push(DeliveryLiveRoutes.issueOf(trip.id)) : null,
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
        if (trip.deliveryPhase case final DeliveryPhase phase when DeliveryProgressBar.isShownFor(phase))
          Padding(
            padding: _cell,
            child: DeliveryProgressBar(phase: phase),
          )
        else if (!trip.isDelivery && TripProgressBar.isShownFor(trip.status))
          Padding(
            padding: _cell,
            child: TripProgressBar(status: trip.status, nextStop: trip.nextStopNumber),
          ),
        if (!trip.isDelivery)
          Padding(
            padding: _cell,
            child: TripTimelineLink(onPressed: () => context.push(TripRoutes.timelineOf(trip.id))),
          ),
      ],
    );
  }

  List<Widget> _deliverySections(BuildContext context, TripDelivery delivery) {
    final description = delivery.item.description;
    final phase = trip.deliveryPhase;
    return [
      Padding(
        padding: _cell,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.sm,
          children: [
            DeliveryPackageLine(delivery: delivery),
            if (description != null && description.trim().isNotEmpty)
              Text(description.trim(), style: SangaTextStyles.cardSubtitle),
          ],
        ),
      ),
      if (phase != null)
        Padding(
          padding: _cell,
          child: Row(
            spacing: SangaSpacing.sm,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Status: ',
                    style: SangaTextStyles.cardSubtitle,
                    children: [TextSpan(text: phase.statusLine, style: SangaTextStyles.cardTitle)],
                  ),
                ),
              ),
              TripLinkChip(
                label: 'Live tracking',
                onPressed: () => context.push(DeliveryLiveRoutes.trackingOf(trip.id)),
              ),
            ],
          ),
        ),
    ];
  }
}
