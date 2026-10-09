import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class NotificationRouting {
  static bool hasDestination(AppNotification notification) => destinationOf(notification) != null;

  static String? destinationOf(AppNotification notification, {String? activeTripId}) {
    final id = notification.action.id;
    return switch (notification.action.route) {
      NotificationRoute.trip when id != null => id == activeTripId ? TripRoutes.tripOf(id) : HistoryRoutes.detailOf(id),
      NotificationRoute.scheduledRide when id != null => BookingRoutes.scheduledRideOf(id),
      NotificationRoute.supportTicket when id != null => SupportRoutes.ticketOf(id),
      NotificationRoute.wallet => WalletRoutes.wallet,
      NotificationRoute.verification => VerificationRoutes.centre,
      NotificationRoute.groupApprovals when id != null => GroupRoutes.approvalsOf(id),
      _ => null,
    };
  }
}
