import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/device_endpoints.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/notifications/notification_routing.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show JsonReader;
import 'package:sanga_ride_push/sanga_ride_push.dart';

abstract final class PushBinding {
  static Future<void> start() async {
    await PushService.instance.initialize(
      PushConfig(
        client: Get.find<ApiService>().client,
        devicesPath: DeviceEndpoints.devices,
        devicePath: DeviceEndpoints.device,
        canRoute: _canRoute,
        canAskPermission: _canAskPermission,
        onTap: _open,
        onForeground: (_) => _refreshNotifications(),
        onPermissionAnswered: _refreshPermission,
      ),
    );
    if (SessionStorage.tokens.hasSession) unawaited(PushService.instance.signedIn());
  }

  static bool _canRoute() {
    final path = SangaRouter.currentPath;
    if (!SessionStorage.tokens.hasSession || path.isEmpty || SangaRoutes.publicPaths.contains(path)) return false;
    return Get.find<SessionRestore>().meState?.onboardingStep == null;
  }

  static bool _canAskPermission() => _canRoute() && SangaRouter.currentPath == SangaRoutes.home;

  static void _open(PushTap tap) {
    _refreshNotifications();
    final destination = _destinationOf(tap) ?? _fallback();
    if (SangaRouter.currentPath == destination) return;
    if (destination == SangaRoutes.home) return SangaRouter.router.go(destination);
    unawaited(SangaRouter.router.push<void>(destination));
  }

  static String? _destinationOf(PushTap tap) {
    try {
      final notification = AppNotification.fromReader(JsonReader(tap.toNotificationJson()));
      return NotificationRouting.destinationOf(
        notification,
        activeTripId: Get.find<SessionRestore>().meState?.activeTrip?.id,
      );
    } catch (error) {
      log('push payload unreadable: ${error.runtimeType}');
      return null;
    }
  }

  static String _fallback() {
    final trip = Get.find<SessionRestore>().meState?.activeTrip;
    return trip == null ? SangaRoutes.home : TripRoutes.tripOf(trip.id);
  }

  static void _refreshNotifications() {
    if (Get.isRegistered<NotificationsController>()) unawaited(Get.find<NotificationsController>().reload());
  }

  static Future<void> _refreshPermission() async {
    if (Get.isRegistered<PermissionCenter>()) await Get.find<PermissionCenter>().check(PermissionKind.notifications);
  }
}
