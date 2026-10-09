import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/approval_sheet.dart';
import 'package:sanga_ride/view/ride/matching/searching_sheet.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/ride/widgets/scheduled_success.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> startMatching(BuildContext context, {bool replacingOffers = false}) async {
  final match = Get.find<RideMatchController>();
  if (replacingOffers) {
    await match.retry();
  } else {
    await match.requestRide();
  }
  if (!context.mounted) {
    match.abandon();
    return;
  }
  await _present(context, replacingOffers: replacingOffers);
}

Future<void> _present(BuildContext context, {required bool replacingOffers}) async {
  final match = Get.find<RideMatchController>();
  final trip = Get.find<RideRequestController>();
  if (match.state is MatchAwaitingApproval) {
    final approval = await showApprovalSheet(context);
    if (!context.mounted) {
      match.abandon();
      return;
    }
    if (approval == ApprovalOutcome.cancelled) return _announceCancelled(match);
  }
  switch (match.state) {
    case MatchBlocked(:final block):
      return _showBlocked(context, block);
    case MatchFailed(:final code) when code != null && trip.tripType.handlesOwnRejections && !replacingOffers:
      return;
    case MatchFailed(:final reason) when reason == MatchFailure.quoteExpired:
      return _showQuoteChanged(context, trip);
    case MatchFailed(:final reason):
      return _showFailure(context, reason, replacingOffers: replacingOffers);
    case MatchNoDriver():
      return _showFailure(context, MatchFailure.noDriverFound, replacingOffers: replacingOffers);
    case MatchScheduled(:final booking):
      return showScheduledSuccess(
        context,
        title: 'Airport pickup booked',
        message: 'We’ll track your flight. Your pick up is ${formatRideMoment(context, booking.scheduledAt)}.',
      );
    case MatchSearching() || MatchOffersReady():
      break;
    default:
      return;
  }
  final outcome = await showSearchingSheet(context);
  if (!context.mounted) return;
  switch (outcome) {
    case SearchOutcome.seeDrivers:
      if (replacingOffers) {
        context.pushReplacement(SangaRoutes.rideOffers);
      } else {
        context.push(SangaRoutes.rideOffers);
      }
    case SearchOutcome.noDriver:
      await _showFailure(context, MatchFailure.noDriverFound, replacingOffers: replacingOffers);
    case SearchOutcome.failed:
      final state = match.state;
      if (state is MatchFailed) await _showFailure(context, state.reason, replacingOffers: replacingOffers);
    case SearchOutcome.cancelled:
      _announceCancelled(match);
    case null:
      break;
  }
}

void _announceCancelled(RideMatchController match) {
  final state = match.state;
  final isConfirmed = state is! MatchCancelled || state.isConfirmed;
  SangaToast.show(
    isConfirmed ? 'Request cancelled' : 'Cancelling. We’ll finish as soon as you’re back online.',
    tone: SangaToastTone.info,
  );
}

Future<void> _showBlocked(BuildContext context, GroupRideBlock block) async {
  final stay = await showSangaStatusSheet(
    context: context,
    status: SangaStatus.caution,
    title: block.title,
    message: block.message,
    actionLabel: 'Got it',
    secondaryLabel: 'Back to home',
  );
  if (context.mounted && !stay) context.go(SangaRoutes.home);
}

Future<void> _showQuoteChanged(BuildContext context, RideRequestController trip) async {
  await trip.refreshQuote();
  if (!context.mounted) return;
  await showSangaStatusSheet(
    context: context,
    status: SangaStatus.caution,
    icon: Icons.sell_outlined,
    title: MatchFailure.quoteExpired.title,
    message: trip.price == null
        ? 'We couldn’t refresh it. Go back and pick your price again.'
        : 'It’s now ${SangaMoney.naira(trip.price!)}. Have a look, then go again.',
    actionLabel: 'Got it',
  );
}

Future<void> _showFailure(BuildContext context, MatchFailure reason, {required bool replacingOffers}) async {
  final match = Get.find<RideMatchController>();
  final checksAgain = reason == MatchFailure.connectionLost || reason == MatchFailure.unconfirmed;
  final shouldRetry = await showSangaStatusSheet(
    context: context,
    status: switch (reason) {
      MatchFailure.noDriverFound || MatchFailure.serverTrouble || MatchFailure.couldNotStart => SangaStatus.failure,
      _ => SangaStatus.caution,
    },
    icon: switch (reason) {
      MatchFailure.offline => Icons.wifi_off_rounded,
      MatchFailure.connectionLost || MatchFailure.unconfirmed => Icons.sync_problem_rounded,
      _ => null,
    },
    title: reason.title,
    message: reason.message,
    actionLabel: checksAgain ? 'Check again' : 'Try again',
    secondaryLabel: 'Back to home',
  );
  if (!context.mounted) return;
  if (!shouldRetry) return context.go(SangaRoutes.home);
  if (checksAgain) {
    await match.recheck();
    if (context.mounted) await _present(context, replacingOffers: replacingOffers);
  } else {
    await startMatching(context, replacingOffers: replacingOffers);
  }
}
