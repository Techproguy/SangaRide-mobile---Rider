import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class NotificationRouting {
  static String? destinationOf(AppNotification notification) {
    final id = notification.action.id;
    return switch (notification.action.route) {
      NotificationRoute.trip when id != null => _tripOf(id),
      NotificationRoute.scheduledRide when id != null => BookingRoutes.scheduledRideOf(id),
      NotificationRoute.supportTicket when id != null => SupportRoutes.ticketOf(id),
      NotificationRoute.wallet => WalletRoutes.wallet,
      NotificationRoute.verification => VerificationRoutes.centre,
      _ => null,
    };
  }

  static String _tripOf(String id) =>
      Get.find<TripController>().trip?.id == id ? TripRoutes.tripOf(id) : HistoryRoutes.detailOf(id);
}
