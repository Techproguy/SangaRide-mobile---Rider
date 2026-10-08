import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_change_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride/view/trip/widgets/trip_progress_bar.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ActiveRidePanel extends StatelessWidget {
  const ActiveRidePanel({
    super.key,
    required this.trip,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    required this.onShare,
    required this.onSafety,
    required this.onAddStops,
    required this.onCancel,
    required this.action,
  });

  final Trip trip;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onShare;
  final VoidCallback onSafety;
  final VoidCallback onAddStops;
  final VoidCallback onCancel;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        Text('Active ride', textAlign: TextAlign.center, style: SangaTextStyles.sheetTitle),
        TripDriverHeader(
          driver: trip.driver,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: SangaSpacing.xs,
            children: [
              SangaActionTile(
                icon: Icons.chat_bubble_rounded,
                label: 'Message',
                onPressed: onMessage,
                badgeCount: unreadCount,
              ),
              SangaActionTile(icon: Icons.phone_rounded, label: 'Call', onPressed: onCall),
            ],
          ),
        ),
        const TripPanelDivider(),
        TripProgressBar(status: trip.status, nextStop: trip.nextStopNumber),
        const TripPanelDivider(),
        TripChangeTiles(
          trip: trip,
          onAddStops: onAddStops,
          onCancel: onCancel,
          alignment: MainAxisAlignment.center,
          leading: [
            SangaActionTile(icon: Icons.ios_share_rounded, label: 'Share', onPressed: onShare),
            SangaActionTile(icon: Icons.shield_rounded, label: 'Safety', onPressed: onSafety, tone: SangaTone.danger),
          ],
        ),
        action,
      ],
    );
  }
}
