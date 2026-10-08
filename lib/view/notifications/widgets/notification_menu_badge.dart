import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationMenuBadge extends StatelessWidget {
  const NotificationMenuBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    return Obx(() {
      final count = controller.unreadCount;
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          if (count > 0)
            Semantics(
              label: '$count unread',
              excludeSemantics: true,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.xs, vertical: 2),
                decoration: const BoxDecoration(color: SangaColors.primary, borderRadius: SangaRadii.pill),
                child: Text(
                  AccountCopy.unreadLabel(count),
                  textAlign: TextAlign.center,
                  style: SangaTextStyles.cardSubtitle.copyWith(
                    color: SangaColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          SangaListRow.chevron,
        ],
      );
    });
  }
}
