import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripActionTiles extends StatelessWidget {
  const TripActionTiles({
    super.key,
    this.unreadCount = 0,
    this.onCall,
    this.onMessage,
    this.onSafety,
    this.onShare,
    this.onAddStops,
    this.onReportIssue,
    this.onCancel,
    this.alignment = MainAxisAlignment.start,
  });

  static const int fittingCount = 4;
  static const double _scrollTileWidth = 60;

  final int unreadCount;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onSafety;
  final VoidCallback? onShare;
  final VoidCallback? onAddStops;
  final VoidCallback? onReportIssue;
  final VoidCallback? onCancel;
  final MainAxisAlignment alignment;

  List<Widget> get _tiles => [
    if (onCall != null) SangaActionTile(icon: Icons.phone_rounded, label: 'Call', onPressed: onCall),
    if (onMessage != null)
      SangaActionTile(icon: Icons.chat_bubble_rounded, label: 'Message', onPressed: onMessage, badgeCount: unreadCount),
    if (onShare != null) SangaActionTile(icon: Icons.ios_share_rounded, label: 'Share', onPressed: onShare),
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
    if (onCancel != null)
      SangaActionTile(icon: Icons.close_rounded, label: 'Cancel trip', onPressed: onCancel, tone: SangaTone.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles;
    if (tiles.length <= fittingCount) {
      return Row(mainAxisAlignment: alignment, spacing: SangaSpacing.sm, children: tiles);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: SangaMotion.pagePhysics,
      clipBehavior: Clip.none,
      child: Row(
        spacing: SangaSpacing.sm,
        children: [
          for (final tile in tiles)
            SizedBox(
              width: _scrollTileWidth,
              child: Center(child: tile),
            ),
        ],
      ),
    );
  }
}
