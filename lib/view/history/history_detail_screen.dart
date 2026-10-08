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
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final _history = Get.find<RideHistoryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _history.openDetail(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _history.detailStateFor(widget.id);
      final title = state is HistoryDetailLoaded ? state.detail.title : 'Trip details';
      return SangaPageLayout(
        title: title,
        children: [
          RideOptionAsyncState(
            isLoading: state is HistoryDetailLoading,
            hasFailed: state is HistoryDetailFailed && state.reason.canRetry,
            errorTitle: 'We couldn’t load the details',
            onRetry: _history.reloadDetail,
            skeletonCount: 3,
            skeletonHeight: 150,
            builder: (context) => switch (_history.detailStateFor(widget.id)) {
              HistoryDetailLoaded(:final detail) => _body(context, detail),
              HistoryDetailFailed(:final reason) => SangaInlineMessage(
                title: reason.title,
                message: reason.message,
                actionLabel: 'Go back',
                onAction: context.pop,
              ),
              HistoryDetailLoading() => const SizedBox.shrink(),
            },
          ),
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
