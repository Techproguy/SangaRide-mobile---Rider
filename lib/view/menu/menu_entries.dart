import 'package:flutter/material.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/places_routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';

class MenuEntry {
  const MenuEntry({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

abstract final class MenuEntries {
  static final List<MenuEntry> all = [
    MenuEntry(label: 'Ride history', icon: Icons.history_rounded, route: HistoryRoutes.history),
    MenuEntry(label: 'Scheduled rides', icon: Icons.event_rounded, route: BookingRoutes.scheduledRides),
    MenuEntry(label: 'Saved places', icon: Icons.bookmark_border_rounded, route: PlacesRoutes.saved),
    MenuEntry(label: 'Safety Centre', icon: Icons.shield_outlined, route: SafetyRoutes.centreOf()),
  ];
}
