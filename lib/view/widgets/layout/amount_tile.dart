import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AmountTile extends StatelessWidget {
  const AmountTile({super.key, required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: const BoxDecoration(color: SangaColors.chipBlue, borderRadius: SangaRadii.field),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.xs,
        children: [
          Text(label, style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.primary)),
          Text(SangaMoney.naira(amount), style: SangaTextStyles.title.copyWith(color: SangaColors.primary)),
        ],
      ),
    );
  }
}
