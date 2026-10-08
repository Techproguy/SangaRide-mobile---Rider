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
