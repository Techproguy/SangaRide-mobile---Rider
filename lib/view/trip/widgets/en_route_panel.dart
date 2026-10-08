import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_contact_tiles.dart';
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
  });

  final Trip trip;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        TripDriverHeader(driver: trip.driver),
        const TripPanelDivider(),
        Row(
          spacing: SangaSpacing.md,
          children: [
            TripContactTiles(unreadCount: unreadCount, onCall: onCall, onMessage: onMessage),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TripEtaLine(etaAt: trip.etaAt, distanceRemainingKm: trip.distanceRemainingKm),
              ),
            ),
          ],
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
