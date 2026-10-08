import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripLinkChip extends StatelessWidget {
  const TripLinkChip({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SangaColors.chipBlue,
      shape: const RoundedRectangleBorder(borderRadius: SangaRadii.digit),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
          child: Text(label, style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.primary)),
        ),
      ),
    );
  }
}
