import 'package:flutter/material.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/notification_routes.dart';
import 'package:sanga_ride/core/router/places_routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/view/groups/widgets/group_menu_trailing.dart';
import 'package:sanga_ride/view/notifications/widgets/notification_menu_badge.dart';
import 'package:sanga_ride/view/verification/widgets/verification_menu_badge.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_menu_balance.dart';

class MenuEntry {
  const MenuEntry({required this.label, required this.icon, required this.route, this.trailing});

  final String label;
  final IconData icon;
  final String route;
  final Widget? trailing;
}

abstract final class MenuEntries {
  static final List<MenuEntry> all = [
    MenuEntry(
      label: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      route: WalletRoutes.wallet,
      trailing: const WalletMenuBalance(),
    ),
    MenuEntry(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: NotificationRoutes.list,
      trailing: const NotificationMenuBadge(),
    ),
    MenuEntry(
      label: 'Family',
      icon: Icons.family_restroom_rounded,
      route: GroupRoutes.hubOf(GroupKind.family),
      trailing: const GroupMenuTrailing(kind: GroupKind.family),
    ),
    MenuEntry(
      label: 'Business',
      icon: Icons.apartment_rounded,
      route: GroupRoutes.hubOf(GroupKind.business),
      trailing: const GroupMenuTrailing(kind: GroupKind.business),
    ),
    MenuEntry(label: 'Ride history', icon: Icons.history_rounded, route: HistoryRoutes.history),
    MenuEntry(label: 'Scheduled rides', icon: Icons.event_rounded, route: BookingRoutes.scheduledRides),
    MenuEntry(label: 'Saved places', icon: Icons.bookmark_border_rounded, route: PlacesRoutes.saved),
    MenuEntry(label: 'Safety Centre', icon: Icons.shield_outlined, route: SafetyRoutes.centreOf()),
    MenuEntry(
      label: 'Verification centre',
      icon: Icons.verified_outlined,
      route: VerificationRoutes.centre,
      trailing: const VerificationMenuBadge(),
    ),
    MenuEntry(label: 'Help and support', icon: Icons.headset_mic_outlined, route: SupportRoutes.home),
  ];
}
