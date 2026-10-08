import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/trip/wrapup/card_details_screen.dart';
import 'package:sanga_ride/view/trip/wrapup/pay_screen.dart';
import 'package:sanga_ride/view/trip/wrapup/rate_screen.dart';
import 'package:sanga_ride/view/trip/wrapup/receipt_screen.dart';
import 'package:sanga_ride/view/trip/wrapup/trip_completed_screen.dart';

abstract final class TripWrapUpRoutes {
  static const String pay = '/trip/:id/pay';
  static const String payCard = '/trip/:id/pay/card';
  static const String complete = '/trip/:id/complete';
  static const String receipt = '/trip/:id/receipt';
  static const String rate = '/trip/:id/rate';

  static String payOf(String id) => pay.replaceFirst(':id', id);

  static String payCardOf(String id) => payCard.replaceFirst(':id', id);

  static String completeOf(String id) => complete.replaceFirst(':id', id);

  static String receiptOf(String id) => receipt.replaceFirst(':id', id);

  static String rateOf(String id) => rate.replaceFirst(':id', id);

  static final List<RouteBase> all = [
    GoRoute(
      path: pay,
      builder: (context, state) => PayScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: payCard,
      builder: (context, state) => CardDetailsScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: complete,
      builder: (context, state) => TripCompletedScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: receipt,
      builder: (context, state) => ReceiptScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: rate,
      builder: (context, state) => RateScreen(tripId: state.pathParameters['id']!),
    ),
  ];
}
