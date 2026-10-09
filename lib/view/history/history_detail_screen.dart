import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/model/history/history_action.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/history/widgets/history_cancellation_card.dart';
import 'package:sanga_ride/view/history/widgets/history_delivery_cards.dart';
import 'package:sanga_ride/view/history/widgets/history_payment_cards.dart';
import 'package:sanga_ride/view/history/widgets/history_rating_card.dart';
import 'package:sanga_ride/view/history/widgets/history_rebook.dart';
import 'package:sanga_ride/view/history/widgets/history_trip_card.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show AppLifecycle;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final _history = Get.find<RideHistoryController>();
  StreamSubscription<void>? _resumeSubscription;

  @override
  void initState() {
    super.initState();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => unawaited(_history.refreshDetail()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _history.openDetail(widget.id));
  }

  @override
  void dispose() {
    _resumeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _history.detailStateFor(widget.id);
      final title = state is HistoryDetailLoaded ? state.detail.title : 'Trip details';
      return SangaPageLayout(
        title: title,
        children: [
          switch (state) {
            HistoryDetailLoading() => const SangaSkeleton.list(count: 3, height: 150),
            HistoryDetailFailed(:final reason) when reason.canRetry => SangaFailureMessage(
              title: reason.title,
              message: reason.message,
              onRetry: _history.reloadDetail,
            ),
            HistoryDetailFailed(:final reason) => SangaFailureMessage(
              title: reason.title,
              message: reason.message,
              icon: Icons.search_off_rounded,
              retryLabel: 'Go back',
              onRetry: context.pop,
            ),
            HistoryDetailLoaded(:final detail, :final isStale) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.md,
              children: [
                if (isStale) SangaStaleNotice(onRetry: _history.refreshDetail),
                _body(context, detail),
              ],
            ),
          },
        ],
      );
    });
  }

  Widget _body(BuildContext context, HistoryDetail detail) {
    final vehicle = detail.vehicle;
    final cancellation = detail.cancellation;
    final delivery = detail.delivery;
    final actions = HistoryAction.availableFor(detail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        HistoryTripCard(
          detail: detail,
          onRebook: detail.canRebook ? () => rebookRide(context, detail.route, detail.category) : null,
        ),
        if (cancellation != null) HistoryCancellationCard(detail: detail, cancellation: cancellation),
        if (delivery != null) HistoryDeliveryCards(delivery: delivery),
        if (detail.isCompleted) HistoryPaymentCards(detail: detail),
        if (vehicle != null)
          SangaVehicleInfo(
            image: detail.category.image,
            lines: [vehicle.title, '${vehicle.colourLabel} colour', 'REG NO: ${vehicle.plateLabel}'],
          ),
        if (detail.isCompleted) HistoryRatingCard(stars: detail.ratedStars),
        if (actions.isNotEmpty)
          SangaSafetyChannelRow(
            icon: Icons.more_horiz_rounded,
            title: 'More actions',
            subtitle: actions.map((action) => action.label).join(', '),
            onTap: () => context.push(HistoryRoutes.actionsOf(detail.id)),
          ),
      ],
    );
  }
}
