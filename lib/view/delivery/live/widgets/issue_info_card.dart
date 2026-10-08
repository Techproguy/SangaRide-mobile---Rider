import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueInfoCard extends StatelessWidget {
  const IssueInfoCard({super.key, required this.rows});

  final List<({IconData icon, String text})> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
      child: Column(
        spacing: SangaSpacing.md,
        children: [
          for (final row in rows)
            Row(
              spacing: SangaSpacing.sm,
              children: [
                Icon(row.icon, size: 20, color: SangaColors.primary),
                Expanded(child: Text(row.text, style: SangaTextStyles.cardSubtitle.copyWith(fontSize: 13))),
              ],
            ),
        ],
      ),
    );
  }
}
