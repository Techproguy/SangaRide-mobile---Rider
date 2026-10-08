import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/searching_sheet.dart';
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
  switch (match.state) {
    case MatchFailed(:final reason):
      return _showFailure(context, reason, replacingOffers: replacingOffers);
    case MatchNoDriver():
      return _showFailure(context, MatchFailure.noDriverFound, replacingOffers: replacingOffers);
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
      Toast.info('Request cancelled');
    case null:
      break;
  }
}

Future<void> _showFailure(BuildContext context, MatchFailure reason, {required bool replacingOffers}) async {
  final shouldRetry = await showSangaStatusSheet(
    context: context,
    status: SangaStatus.failure,
    title: reason.title,
    message: reason.message,
    actionLabel: 'Try again',
    secondaryLabel: 'Back to home',
  );
  if (!context.mounted) return;
  if (shouldRetry) {
    await startMatching(context, replacingOffers: replacingOffers);
  } else {
    context.go(SangaRoutes.home);
  }
}
