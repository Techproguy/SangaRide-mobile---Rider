import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripTimelineLink extends StatelessWidget {
  const TripTimelineLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SangaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: SangaRadii.field,
        side: BorderSide(color: SangaColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(SangaSpacing.sm),
          child: Row(
            spacing: SangaSpacing.sm,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: SangaColors.primaryTint, borderRadius: SangaRadii.digit),
                child: const Icon(Icons.timeline_rounded, size: 18, color: SangaColors.primary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text('Trip timeline', style: SangaTextStyles.cardTitle),
                    Text('See key events during your ride', style: SangaTextStyles.cardSubtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 22, color: SangaColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
