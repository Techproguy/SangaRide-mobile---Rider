import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/core/router/notification_routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  Future<void> _open(BuildContext context) async {
    await Get.find<PermissionCenter>().offer(PermissionKind.notifications, context);
    if (context.mounted) unawaited(context.push(NotificationRoutes.list));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    return Obx(() {
      final count = controller.unreadCount;
      return SangaMapButton(
        tooltip: count == 0 ? 'Notifications' : 'Notifications, $count unread',
        onPressed: () => _open(context),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(AccountCopy.unreadLabel(count)),
          backgroundColor: SangaColors.dangerStrong,
          child: const Icon(Icons.notifications_none_rounded, color: SangaColors.textPrimary, size: 26),
        ),
      );
    });
  }
}
