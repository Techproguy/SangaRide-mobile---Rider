import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_action_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerifyingPanel extends StatelessWidget {
  const VerifyingPanel({
    super.key,
    required this.trip,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    required this.onSafety,
    required this.onSos,
    required this.onAddStops,
    required this.onCancel,
    required this.onShowPin,
    required this.onReport,
  });

  final Trip trip;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onSafety;
  final VoidCallback onSos;
  final VoidCallback onAddStops;
  final VoidCallback onCancel;
  final VoidCallback onShowPin;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        TripDriverHeader(driver: trip.driver),
        const TripPanelDivider(),
        Text('Share your PIN to start the ride', style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.primary)),
        TripActionTiles(
          unreadCount: unreadCount,
          onCall: onCall,
          onMessage: onMessage,
          onSafety: onSafety,
          onSos: onSos,
          onAddStops: trip.canAddStops ? onAddStops : null,
          onCancel: trip.canChange ? onCancel : null,
        ),
        SangaButton.primary(label: 'Show trip PIN', onPressed: onShowPin),
        SangaButton.muted(label: 'Report an issue', onPressed: onReport),
      ],
    );
  }
}
