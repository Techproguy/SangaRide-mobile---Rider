import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ValueWarning extends StatelessWidget {
  const ValueWarning({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: const BoxDecoration(color: SangaColors.dangerSoft, borderRadius: SangaRadii.field),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.sm,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: SangaColors.dangerStrong),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xxs,
              children: [
                Text(title, style: SangaTextStyles.cardTitleStrong.copyWith(color: SangaColors.danger)),
                Text(message, style: SangaTextStyles.cardBody.copyWith(color: SangaColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
