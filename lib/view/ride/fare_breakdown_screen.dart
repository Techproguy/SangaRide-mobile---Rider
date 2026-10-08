import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_fare_lines.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_quote.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FareBreakdownScreen extends StatelessWidget {
  const FareBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'Fare breakdown',
      subtitle: 'See exactly what you pay for',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Continue',
          onPressed: ride.estimate == null || ride.pricing == null ? null : () => context.push(SangaRoutes.rideTiming),
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: ride.isEstimating,
            hasFailed: ride.estimate == null || ride.pricing == null,
            errorTitle: 'We couldn’t load your fare',
            onRetry: ride.loadQuote,
            skeletonCount: 1,
            skeletonHeight: 200,
            builder: (context) => _buildBreakdown(ride),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdown(RideRequestController ride) {
    final estimate = ride.estimate;
    final pricing = ride.pricing;
    final option = ride.option;
    final price = ride.price;
    if (estimate == null || pricing == null || option == null || price == null) return const SizedBox.shrink();
    return SangaFareBreakdown(
      title: 'Estimated fare',
      lines: rideFareLines(
        estimate: estimate,
        pricing: pricing,
        pricePerKm: option.pricePerKm,
        isRoundTrip: ride.tripType == TripType.roundTrip,
      ),
      totalLabel: 'TOTAL ESTIMATE',
      total: SangaMoney.naira(price),
    );
  }
}
