import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_icons.dart';
import 'package:sanga_ride/view/delivery/send/widgets/tier_card.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryTierScreen extends StatefulWidget {
  const DeliveryTierScreen({super.key, required this.isEditing});

  final bool isEditing;

  @override
  State<DeliveryTierScreen> createState() => _DeliveryTierScreenState();
}

class _DeliveryTierScreenState extends State<DeliveryTierScreen> {
  final _delivery = Get.find<SendDeliveryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    await _delivery.loadCatalog();
    await _delivery.ensureQuote(force: force);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Delivery tier',
      subtitle: 'Pick how fast you need it there',
      footer: Obx(
        () => SangaButton.primary(
          label: widget.isEditing ? 'Save' : 'Continue',
          onPressed: _delivery.selectedTier == null
              ? null
              : () => DeliveryRoutes.advance(context, next: DeliveryRoutes.recipient, isEditing: widget.isEditing),
        ),
      ),
      children: [
        Obx(() {
          final state = _delivery.quoteState;
          final hasFailed = state is QuoteFailed || _delivery.catalogState is DeliveryCatalogFailed;
          return RideOptionAsyncState(
            isLoading: !hasFailed && (state is QuoteIdle || state is QuoteLoading),
            hasFailed: hasFailed,
            errorTitle: 'We couldn’t get your prices',
            onRetry: () => _load(force: true),
            skeletonCount: 4,
            skeletonHeight: 92,
            builder: _tiers,
          );
        }),
      ],
    );
  }

  Widget _tiers(BuildContext context) {
    final quote = _delivery.quote;
    final catalog = _delivery.catalog;
    if (quote == null || catalog == null) return const SizedBox.shrink();
    final recommended = catalog.tierOf(quote.recommendedTier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        if (recommended != null)
          SangaNotice(
            tone: SangaTone.neutral,
            icon: Icons.info_outline_rounded,
            message: '${recommended.label} is the best fit for what you’re sending.',
          ),
        for (final tier in quote.tiers)
          if (catalog.tierOf(tier.id) case final info?)
            TierCard(
              icon: deliveryTierIcon(tier.id),
              label: info.label,
              blurb: info.blurb,
              eta: deliveryEtaLabel(tier.etaMinutes),
              fare: tier.fare,
              isSelected: _delivery.draft.tierId == tier.id,
              isRecommended: tier.isRecommended || quote.recommendedTier == tier.id,
              onTap: () => _delivery.selectTier(tier.id),
            ),
      ],
    );
  }
}
