import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripContactTiles extends StatelessWidget {
  const TripContactTiles({
    super.key,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    this.onShare,
  });

  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback? onShare;

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
      ],
    );
  }
}
