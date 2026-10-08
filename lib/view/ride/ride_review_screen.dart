import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_review_cards.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideReviewScreen extends StatelessWidget {
  const RideReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'Review your ride',
      footer: Obx(
        () => SangaButton.primary(
          label: ride.timing == RideTiming.later ? 'Schedule ride' : 'Find a driver',
          onPressed: ride.estimate == null || ride.pricing == null
              ? null
              : () => context.push(SangaRoutes.rideMatching),
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
