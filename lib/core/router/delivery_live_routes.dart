import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/view/delivery/live/confirm_pickup_screen.dart';
import 'package:sanga_ride/view/delivery/live/delivery_issue_screen.dart';
import 'package:sanga_ride/view/delivery/live/delivery_issue_status_screen.dart';
import 'package:sanga_ride/view/delivery/live/delivery_proof_screen.dart';
import 'package:sanga_ride/view/delivery/live/delivery_tracking_screen.dart';

abstract final class DeliveryLiveRoutes {
  static const String confirmPickup = '/trip/:id/delivery/confirm-pickup';
  static const String tracking = '/trip/:id/delivery/tracking';
  static const String proof = '/trip/:id/delivery/proof';
  static const String issue = '/trip/:id/delivery/issue';
  static const String issueStatus = '/trip/:id/delivery/issue/status';

  static String confirmPickupOf(String id) => confirmPickup.replaceFirst(':id', id);

  static String trackingOf(String id) => tracking.replaceFirst(':id', id);

  static String proofOf(String id) => proof.replaceFirst(':id', id);

  static String issueOf(String id) => issue.replaceFirst(':id', id);

  static String issueStatusOf(String id) => issueStatus.replaceFirst(':id', id);

  static void popToTrip(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == TripRoutes.trip);
  }

  static final List<RouteBase> all = [
    GoRoute(
      path: confirmPickup,
      builder: (context, state) => ConfirmPickupScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: tracking,
      builder: (context, state) => DeliveryTrackingScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: proof,
      builder: (context, state) => DeliveryProofScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: issue,
      builder: (context, state) => DeliveryIssueScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: issueStatus,
      builder: (context, state) => DeliveryIssueStatusScreen(tripId: state.pathParameters['id']!),
    ),
  ];
}
