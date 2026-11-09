import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride/view/notifications/notification_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationMenuBadge extends StatelessWidget {
  const NotificationMenuBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    return Obx(() {
      final count = controller.unreadCount;
      if (count == 0) return const SizedBox.shrink();
      return SangaCountBadge(label: AccountCopy.unreadLabel(count), semanticLabel: NotificationCopy.unread(count));
    });
  }
}
