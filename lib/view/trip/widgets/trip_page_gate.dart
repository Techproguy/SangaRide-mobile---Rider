import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripPageGate extends StatefulWidget {
  const TripPageGate({super.key, required this.tripId, required this.title, required this.child});

  final String tripId;
  final String title;
  final Widget child;

  @override
  State<TripPageGate> createState() => _TripPageGateState();
}

class _TripPageGateState extends State<TripPageGate> {
  final _trip = Get.find<TripController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_trip.open(widget.tripId));
    });
  }

  @override
  void dispose() {
    _trip.close(onlyTripId: widget.tripId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _trip.state;
      if (state is! TripFailed) return widget.child;
      final reason = state.reason;
      return SangaPageLayout(
        title: widget.title,
        children: [
          SangaFailureMessage(
            title: reason.title,
            message: reason.message,
            onRetry: reason.canRetry ? () => unawaited(_trip.retryLoad()) : null,
          ),
        ],
      );
    });
  }
}
