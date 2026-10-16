import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
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
  static const double _offerFieldWidth = 108;

  final _ride = Get.find<RideRequestController>();
  late final _offer = TextEditingController(text: _ride.fairFareOffer?.wholeMajor.toString() ?? '');

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
  void dispose() {
    _offer.dispose();
    super.dispose();
  }

  void _onOfferChanged(int? amount) {
    _ride.selectPricing(PricingOption.fairFare);
    _ride.setFairFareOffer(amount == null || amount == 0 ? null : Money.major(amount));
  }

  void _continue() {
    final next = _ride.pricing?.isNegotiated ?? false ? BookingRoutes.afterFare(_ride.tripType) : SangaRoutes.rideFare;
    context.push(next);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Choose a pricing option',
      subtitle: 'These are estimates for your trip.',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Continue',
          onPressed: _ride.price == null || _ride.estimate == null ? null : _continue,
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.isEstimating,
            hasFailed: _ride.estimate == null,
            errorTitle: 'We couldn’t work out your prices',
            failureMessage: _ride.estimateProblem?.message,
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
          if (option.isNegotiated)
            ?_fairFareCard(estimate)
          else if (estimate.pricing[option] case final price?)
            SangaOptionCard(
              leading: SangaIconBadge(child: Icon(_iconFor(option))),
              title: option.label,
              subtitle: option.description,
              value: price.format(),
              isSelected: _ride.pricing == option,
              onTap: () => _ride.selectPricing(option),
            ),
      ],
    );
  }

  Widget? _fairFareCard(FareEstimate estimate) {
    final range = estimate.fairFare;
    if (range == null) return null;
    final problem = _ride.pricing == PricingOption.fairFare ? _ride.fairFareProblem : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        SangaOptionCard(
          leading: SangaIconBadge(child: Icon(_iconFor(PricingOption.fairFare))),
          title: PricingOption.fairFare.label,
          subtitle: PricingOption.fairFare.description,
          trailing: SizedBox(
            width: _offerFieldWidth,
            child: SangaMoneyField(controller: _offer, hintText: 'Amount', onChanged: _onOfferChanged),
          ),
          isSelected: _ride.pricing == PricingOption.fairFare,
          onTap: () => _ride.selectPricing(PricingOption.fairFare),
        ),
        if (problem != null)
          Text(
            problem.messageFor(range),
            style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.dangerStrong),
          ),
      ],
    );
  }
}
