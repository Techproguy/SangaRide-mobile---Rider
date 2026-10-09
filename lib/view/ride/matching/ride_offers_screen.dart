import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride/view/ride/matching/widgets/offer_card.dart';
import 'package:sanga_ride/view/ride/matching/widgets/searching_sheet_content.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOffersScreen extends StatefulWidget {
  const RideOffersScreen({super.key});

  @override
  State<RideOffersScreen> createState() => _RideOffersScreenState();
}

class _RideOffersScreenState extends State<RideOffersScreen> {
  final _match = Get.find<RideMatchController>();
  Worker? _worker;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_begin()));
  }

  @override
  void dispose() {
    _worker?.dispose();
    _match.stopOffersRefresh();
    super.dispose();
  }

  Future<void> _begin() async {
    await _match.resume();
    if (!mounted) return;
    _worker = ever(_match.stateRx, _onState);
    _onState(_match.state);
  }

  void _onState(RideMatchState state) {
    if (!mounted) return;
    if (state is MatchOffersReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_match.loadOffers());
      });
    } else if (state is MatchBrowsing) {
      _match.startOffersRefresh();
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(SangaRoutes.home);
    }
  }

  Future<void> _leave() async {
    if (!_match.isLive) return _close();
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
    _close();
  }

  Future<void> _accept(DriverOffer offer) async {
    final isHeld = await _match.hold(offer);
    if (isHeld && mounted) context.push(SangaRoutes.rideConfirmDriver);
  }

  Future<void> _cancelSearch() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    await _match.cancelRequest();
    if (mounted) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: SangaPageLayout(title: 'Available drivers', onBack: _leave, children: [Obx(() => _body(context))]),
    );
  }

  Widget _body(BuildContext context) {
    final state = _match.state;
    return switch (state) {
      MatchBrowsing() => _buildOffers(context, state),
      MatchOffersLoading() ||
      MatchOffersReady() ||
      MatchResuming() ||
      MatchStarting() => const SangaSkeleton.list(count: 3, height: 150),
      MatchOffersFailed(:final problem) => SangaFailureMessage(
        title: 'We couldn’t load your drivers',
        message: problem.message,
        onRetry: _match.loadOffers,
      ),
      MatchSearching(:final request, :final isReconnecting) => Padding(
        padding: const EdgeInsets.only(top: SangaSpacing.xl),
        child: SearchingSheetContent(
          steps: request.stepLabels,
          doneCount: request.stepsDone,
          continueAt: null,
          isReconnecting: isReconnecting,
          isCancelling: _isCancelling,
          onCancel: _cancelSearch,
          onContinue: () {},
        ),
      ),
      MatchAwaitingApproval() => const SangaEmptyMessage(
        icon: Icons.hourglass_top_rounded,
        title: 'Waiting for approval',
        message: 'An admin has to say yes before this ride goes out. We’ll carry on the moment they do.',
      ),
      MatchNoDriver() => SangaEmptyMessage(
        icon: Icons.directions_car_outlined,
        title: MatchFailure.noDriverFound.title,
        message: MatchFailure.noDriverFound.message,
        actionLabel: CommonCopy.backToHome,
        onAction: _close,
      ),
      MatchFailed(:final reason) => SangaFailureMessage(
        title: reason.title,
        message: reason.message,
        retryLabel: 'Check again',
        onRetry: _match.recheck,
      ),
      MatchCancelled() || MatchIdle() || MatchBlocked() || MatchScheduled() || MatchConfirmed() => SangaEmptyMessage(
        icon: Icons.event_busy_rounded,
        title: 'This request has ended',
        message: 'Start a new one whenever you’re ready.',
        actionLabel: CommonCopy.backToHome,
        onAction: () => context.go(SangaRoutes.home),
      ),
    };
  }

  Widget _buildOffers(BuildContext context, MatchBrowsing state) {
    if (state.rows.isEmpty) {
      return SangaEmptyMessage(
        icon: Icons.person_search_rounded,
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
