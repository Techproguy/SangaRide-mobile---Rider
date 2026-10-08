import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_review_cards.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideReviewScreen extends StatefulWidget {
  const RideReviewScreen({super.key});

  @override
  State<RideReviewScreen> createState() => _RideReviewScreenState();
}

class _RideReviewScreenState extends State<RideReviewScreen> {
  final _match = Get.find<RideMatchController>();

  @override
  void dispose() {
    if (_match.isLive) scheduleMicrotask(_match.abandon);
    super.dispose();
  }

  Future<void> _submit(RideRequestController ride) async {
    if (ride.timing == RideTiming.later) return _schedule();
    await startMatching(context);
  }

  Future<void> _schedule() async {
    final booking = await _match.scheduleRide();
    if (!mounted || booking == null) return;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'Ride scheduled',
      message: 'Your ride is booked for ${formatRideSchedule(context, booking.scheduledAt)}.',
      actionLabel: 'Done',
    );
    if (mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return Obx(() => PopScope(canPop: !_match.isStarting, child: _layout(context, ride)));
  }

  Widget _layout(BuildContext context, RideRequestController ride) {
    return SangaPageLayout(
      title: 'Review your ride',
      footer: Obx(
        () => SangaButton.primary(
          label: ride.timing == RideTiming.later ? 'Schedule ride' : 'Find a driver',
          isLoading: _match.isStarting,
          onPressed: ride.estimate == null || ride.pricing == null || _match.isLive ? null : () => _submit(ride),
        ),
      ),
      children: [
        Obx(() {
          final pricing = ride.pricing;
          final price = ride.price;
          return Column(
            spacing: SangaSpacing.md,
            children: [
              RideOptionRouteCard(pickup: ride.pickup, stops: ride.stops.toList(), dropoff: ride.dropoff),
              if (ride.option case final option?) _vehicleCard(option),
              if (pricing != null && price != null)
                SangaFareBreakdown(
                  title: 'Ride details',
                  lines: [
                    SangaFareLine('Pricing', pricing.label),
                    SangaFareLine('Trip', ride.tripType.label),
                    SangaFareLine('When', _timingLabel(context, ride)),
                    SangaFareLine('Preferences', _preferencesLabel(ride.preferences)),
                    if (ride.preferences.driverLanguage != const RidePreferences().driverLanguage)
                      SangaFareLine('Driver language', ride.preferences.driverLanguage),
                  ],
                  totalLabel: 'TOTAL ESTIMATE',
                  total: SangaMoney.naira(price),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _vehicleCard(RideOption option) => SangaVehicleCard(
    image: option.category.image,
    name: option.name,
    description: option.description,
    seats: option.seats,
    price: SangaMoney.perKm(option.pricePerKm),
    isSelected: true,
  );

  String _preferencesLabel(RidePreferences preferences) {
    final labels = preferences.activeLabels;
    return labels.isEmpty ? 'None' : labels.join(', ');
  }

  String _timingLabel(BuildContext context, RideRequestController ride) {
    final scheduledAt = ride.scheduledAt;
    if (ride.timing == RideTiming.now || scheduledAt == null) return RideTiming.now.label;
    return formatRideSchedule(context, scheduledAt);
  }
}
