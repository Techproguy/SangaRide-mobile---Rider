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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        const SangaSectionHeader('Safety tools'),
        SangaListGroup(
          children: [
            if (onShare case final onShare?)
              SangaListRow.badge(icon: Icons.ios_share_rounded, title: 'Share trip', onTap: onShare),
            if (onTripDetails case final onTripDetails?)
              SangaListRow.badge(icon: Icons.description_outlined, title: 'Trip details', onTap: onTripDetails),
            SangaListRow.badge(
              icon: Icons.report_gmailerrorred_rounded,
              title: 'Report a safety issue',
              onTap: onReport,
            ),
          ],
        ),
      ],
    );
  }
}
