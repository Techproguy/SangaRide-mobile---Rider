import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/match_check_rows.dart';
import 'package:sanga_ride/view/trip/widgets/trip_contact_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride/view/trip/widgets/trip_vehicle_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DetailsCheckSheet extends StatelessWidget {
  const DetailsCheckSheet({
    super.key,
    required this.trip,
    required this.unreadCount,
    required this.isConfirming,
    required this.onCall,
    required this.onMessage,
    required this.onConfirm,
    required this.onReport,
  });

  final Trip trip;
  final int unreadCount;
  final bool isConfirming;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onConfirm;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: [
          TripDriverHeader(driver: trip.driver),
          TripVehicleCard(trip: trip),
          const TripPanelDivider(),
          Center(
            child: TripContactTiles(unreadCount: unreadCount, onCall: onCall, onMessage: onMessage),
          ),
          const TripPanelDivider(),
          const MatchCheckRows(),
          SangaButton.primary(
            label: 'Yes, details match, show trip PIN',
            isLoading: isConfirming,
            onPressed: onConfirm,
          ),
          SangaButton.muted(label: 'Report an issue', onPressed: isConfirming ? null : onReport),
        ],
      ),
    );
  }
}
