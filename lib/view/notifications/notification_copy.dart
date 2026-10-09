import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';

extension NotificationKindIcon on NotificationKind {
  IconData get icon => switch (this) {
    NotificationKind.message => Icons.chat_bubble_outline_rounded,
    NotificationKind.payment => Icons.payments_outlined,
    NotificationKind.delivery => Icons.inventory_2_outlined,
    NotificationKind.ride => Icons.directions_car_outlined,
    NotificationKind.support => Icons.headset_mic_outlined,
    NotificationKind.verification => Icons.verified_outlined,
    NotificationKind.safety => Icons.shield_outlined,
    NotificationKind.general => Icons.notifications_none_rounded,
  };
}

abstract final class NotificationCopy {
  static const String title = 'Notifications';
  static const String permissionOff = 'Notifications are off, so updates only show up here. Turn them on in Settings.';
  static const String markAllRead = 'Mark all as read';
  static const String allQuiet = 'All quiet';
  static const String allQuietMessage = 'You’re all caught up. New updates will show up here.';
  static const String loadFailed = 'We couldn’t load your notifications';

  static String bellTooltip(int unread) => unread == 0 ? title : '$title, $unread unread';

  static String unread(int count) => '$count unread';
}
