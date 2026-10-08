import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_contact_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ArrivedPanel extends StatelessWidget {
  const ArrivedPanel({
    super.key,
    required this.trip,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    required this.onConfirmDetails,
  });

  final Trip trip;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onConfirmDetails;

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
              child: Text(
                'Your driver is at the pickup',
                textAlign: TextAlign.end,
                style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.success),
              ),
            ),
          ],
        ),
        SangaButton.primary(label: 'Confirm details', onPressed: onConfirmDetails),
      ],
    );
  }
}
