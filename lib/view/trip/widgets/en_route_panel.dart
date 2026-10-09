import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_action_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_eta_line.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class EnRoutePanel extends StatelessWidget {
  const EnRoutePanel({
    super.key,
    required this.trip,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    required this.onSafety,
    required this.onAddStops,
    required this.onCancel,
  });

  final Trip trip;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onSafety;
  final VoidCallback onAddStops;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        TripDriverHeader(driver: trip.driver),
        const TripPanelDivider(),
        TripEtaLine(etaAt: trip.etaAt, distanceRemainingKm: trip.distanceRemainingKm),
        TripActionTiles(
          unreadCount: unreadCount,
          onCall: onCall,
          onMessage: onMessage,
          onSafety: onSafety,
          onAddStops: trip.canAddStops ? onAddStops : null,
          onCancel: trip.canChange ? onCancel : null,
        ),
        const SangaNotice(
          message: 'Your driver is heading to your pickup, please be ready',
          tone: SangaTone.neutral,
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }
}
