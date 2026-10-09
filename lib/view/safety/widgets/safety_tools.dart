import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SafetyTools extends StatelessWidget {
  const SafetyTools({super.key, required this.onReport, this.onShare, this.onTripDetails});

  final VoidCallback onReport;
  final VoidCallback? onShare;
  final VoidCallback? onTripDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        const SangaSectionHeader('Safety tools'),
        Row(
          spacing: SangaSpacing.lg,
          children: [
            if (onShare != null)
              SangaActionTile(icon: Icons.ios_share_rounded, label: 'Share trip', onPressed: onShare),
            if (onTripDetails != null)
              SangaActionTile(icon: Icons.description_outlined, label: 'Trip details', onPressed: onTripDetails),
            SangaActionTile(icon: Icons.report_gmailerrorred_rounded, label: 'Report issue', onPressed: onReport),
          ],
        ),
      ],
    );
  }
}
