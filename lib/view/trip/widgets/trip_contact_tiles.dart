import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripContactTiles extends StatelessWidget {
  const TripContactTiles({
    super.key,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    this.onShare,
    this.onSafety,
    this.onAddStops,
    this.onReportIssue,
  });

  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback? onShare;
  final VoidCallback? onSafety;
  final VoidCallback? onAddStops;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        SangaActionTile(icon: Icons.phone_rounded, label: 'Call', onPressed: onCall),
        if (onShare != null) SangaActionTile(icon: Icons.ios_share_rounded, label: 'Share', onPressed: onShare),
        SangaActionTile(
          icon: Icons.chat_bubble_rounded,
          label: 'Message',
          onPressed: onMessage,
          badgeCount: unreadCount,
        ),
        if (onSafety != null)
          SangaActionTile(icon: Icons.shield_rounded, label: 'Safety', onPressed: onSafety, tone: SangaTone.danger),
        if (onAddStops != null)
          SangaActionTile(icon: Icons.add_location_alt_rounded, label: 'Add stops', onPressed: onAddStops),
        if (onReportIssue != null)
          SangaActionTile(
            icon: Icons.report_gmailerrorred_rounded,
            label: 'Report issue',
            onPressed: onReportIssue,
            tone: SangaTone.danger,
          ),
      ],
    );
  }
}
