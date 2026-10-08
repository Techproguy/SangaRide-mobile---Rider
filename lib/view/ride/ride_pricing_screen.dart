import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_quote.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RidePricingScreen extends StatefulWidget {
  const RidePricingScreen({super.key});

  @override
  State<RidePricingScreen> createState() => _RidePricingScreenState();
}

class _RidePricingScreenState extends State<RidePricingScreen> {
  final _ride = Get.find<RideRequestController>();

  static IconData _iconFor(PricingOption option) => switch (option) {
    PricingOption.standard => Icons.balance_rounded,
    PricingOption.fairFare => Icons.handshake_outlined,
    PricingOption.saver => Icons.savings_outlined,
    PricingOption.priority => Icons.bolt_rounded,
  };

  @override
  void initState() {
    super.initState();
    _ride.loadQuote();
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Choose a pricing option',
      subtitle: 'These are estimates for your trip.',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Continue',
          onPressed: _ride.pricing == null || _ride.estimate == null ? null : () => context.push(SangaRoutes.rideFare),
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.isEstimating,
            hasFailed: _ride.estimate == null,
            errorTitle: 'We couldn’t work out your prices',
            onRetry: _ride.loadQuote,
            skeletonCount: PricingOption.values.length,
            builder: _buildOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context) {
    final estimate = _ride.estimate;
    if (estimate == null) return const SizedBox.shrink();
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final option in PricingOption.values)
          if (estimate.pricing[option] case final price?)
            SangaOptionCard(
              leading: SangaIconBadge(child: Icon(_iconFor(option))),
              title: option.label,
              subtitle: option.description,
              value: SangaMoney.naira(price),
              isSelected: _ride.pricing == option,
              onTap: () => _ride.selectPricing(option),
            ),
      ],
    );
  }
}
