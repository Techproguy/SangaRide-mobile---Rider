import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/notifications/notification_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SangaNotificationRow(
      title: notification.title,
      body: notification.body,
      timeLabel: TimeFormat.ago(notification.createdAt),
      icon: notification.kind.icon,
      isUnread: !notification.isRead,
      onTap: onTap,
    );
  }
}
