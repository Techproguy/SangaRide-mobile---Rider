import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/notification_routes.dart';
import 'package:sanga_ride/core/router/places_routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/group_menu_trailing.dart';
import 'package:sanga_ride/view/notifications/widgets/notification_menu_badge.dart';
import 'package:sanga_ride/view/verification/widgets/verification_menu_badge.dart';

class MenuEntry {
  const MenuEntry({required this.label, required this.icon, required this.route, this.trailing, this.subtitle});

  final String label;
  final IconData icon;
  final String route;
  final Widget? trailing;
  final String? Function()? subtitle;
}

class MenuSection {
  const MenuSection({required this.title, required this.entries});

  final String title;
  final List<MenuEntry> entries;
}

abstract final class MenuEntries {
  static final List<MenuSection> sections = [
    MenuSection(
      title: 'Rides',
      entries: [
        MenuEntry(label: 'Ride history', icon: Icons.history_rounded, route: HistoryRoutes.history),
        MenuEntry(label: 'Scheduled rides', icon: Icons.event_outlined, route: BookingRoutes.scheduledRides),
        MenuEntry(label: 'Saved places', icon: Icons.bookmark_border_rounded, route: PlacesRoutes.saved),
      ],
    ),
    MenuSection(
      title: 'Groups',
      entries: [
        MenuEntry(
          label: 'Family',
          icon: GroupCopy.icon(GroupKind.family),
          route: GroupRoutes.hubOf(GroupKind.family),
          trailing: const GroupMenuTrailing(kind: GroupKind.family),
          subtitle: () => Get.find<GroupsController>().groupOf(GroupKind.family)?.name,
        ),
        MenuEntry(
          label: 'Business',
          icon: GroupCopy.icon(GroupKind.business),
          route: GroupRoutes.hubOf(GroupKind.business),
          trailing: const GroupMenuTrailing(kind: GroupKind.business),
          subtitle: () => Get.find<GroupsController>().groupOf(GroupKind.business)?.name,
        ),
      ],
    ),
    MenuSection(
      title: 'Account',
      entries: [
        MenuEntry(
          label: 'Notifications',
          icon: Icons.notifications_none_rounded,
          route: NotificationRoutes.list,
          trailing: const NotificationMenuBadge(),
        ),
        MenuEntry(
          label: 'Verification centre',
          icon: Icons.verified_outlined,
          route: VerificationRoutes.centre,
          trailing: const VerificationMenuBadge(),
        ),
      ],
    ),
    MenuSection(
      title: 'Help',
      entries: [
        MenuEntry(label: 'Safety centre', icon: Icons.shield_outlined, route: SafetyRoutes.centreOf()),
        MenuEntry(label: 'Help and support', icon: Icons.headset_mic_outlined, route: SupportRoutes.home),
      ],
    ),
  ];
}
