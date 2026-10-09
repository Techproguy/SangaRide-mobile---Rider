import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_issue_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_live_status.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo_strip.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_timeline_entries.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final _trip = Get.find<TripController>();
  final _issue = Get.find<DeliveryIssueController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_issue.open(widget.tripId)));
  }

  @override
  void dispose() {
    _issue.release();
    super.dispose();
  }

  void _reportOrOpen() {
    final route = _issue.hasOpenIssue
        ? DeliveryLiveRoutes.issueStatusOf(widget.tripId)
        : DeliveryLiveRoutes.issueOf(widget.tripId);
    unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context) {
    return TripPageGate(
      tripId: widget.tripId,
      title: 'Live tracking',
      child: Obx(() {
        final trip = _trip.trip;
        final delivery = trip?.delivery;
        final isLive = trip != null && !trip.status.isTerminal;
        return SangaPageLayout(
          title: 'Live tracking',
          footer: isLive
              ? SangaButton.primary(
                  label: _issue.hasOpenIssue ? 'See your report' : CommonCopy.reportIssue,
                  onPressed: _reportOrOpen,
                )
              : null,
          children: [
            if (trip == null || delivery == null)
              const SangaSkeleton.heights([72, 220, 120])
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SangaSpacing.xl,
                children: [
                  if (trip.deliveryPhase case final DeliveryPhase phase) DeliveryLiveStatus(trip: trip, phase: phase),
                  SangaTimeline(entries: DeliveryTimelineEntries.of(delivery)),
                  DeliveryPhotoStrip(delivery: delivery),
                ],
              ),
          ],
        );
      }),
    );
  }
}
