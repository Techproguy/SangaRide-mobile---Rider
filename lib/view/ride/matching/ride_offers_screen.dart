import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride/view/ride/matching/widgets/offer_card.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOffersScreen extends StatefulWidget {
  const RideOffersScreen({super.key});

  @override
  State<RideOffersScreen> createState() => _RideOffersScreenState();
}

class _RideOffersScreenState extends State<RideOffersScreen> {
  final _match = Get.find<RideMatchController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _match.loadOffers());
  }

  Future<void> _leave() async {
    if (!_match.isLive) {
      context.pop();
      return;
    }
    final shouldStop = await showSangaPromptSheet(
      context: context,
      icon: Icons.close_rounded,
      title: 'Stop looking?',
      message: 'If you go back, we’ll cancel this request and these drivers will be gone.',
      actionLabel: 'Yes, go back',
      dismissLabel: 'Stay here',
    );
    if (!shouldStop || !mounted) return;
    _match.abandon();
    context.pop();
  }

  Future<void> _accept(DriverOffer offer) async {
    final isHeld = await _match.hold(offer);
    if (isHeld && mounted) context.push(SangaRoutes.rideConfirmDriver);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: SangaPageLayout(
        title: 'Available drivers',
        onBack: _leave,
        children: [
          Obx(() {
            final state = _match.state;
            return RideOptionAsyncState(
              isLoading: state is MatchOffersLoading || state is MatchOffersReady,
              hasFailed: state is MatchOffersFailed,
              errorTitle: 'We couldn’t load your drivers',
              skeletonHeight: 150,
              onRetry: _match.loadOffers,
              builder: _buildOffers,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOffers(BuildContext context) {
    final state = _match.state;
    if (state is! MatchBrowsing) return const SizedBox.shrink();
    if (state.rows.isEmpty) {
      return SangaInlineMessage(
        title: 'No more offers yet',
        message: 'Want us to keep looking? We’ll send your request out again.',
        actionLabel: 'Keep searching',
        onAction: () => startMatching(context, replacingOffers: true),
      );
    }
    final acceptingId = state is MatchOffersListed ? state.acceptingOfferId : null;
    return Column(
      children: [
        for (final row in state.rows)
          OfferCard(
            key: ValueKey(row.offer.id),
            offer: row.offer,
            isLeaving: row.isLeaving,
            isAccepting: acceptingId == row.offer.id,
            isBusy: acceptingId != null,
            onIgnore: () => _match.ignore(row.offer),
            onAccept: () => _accept(row.offer),
          ),
      ],
    );
  }
}
