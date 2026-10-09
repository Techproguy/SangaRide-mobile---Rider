import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RebookButton extends StatelessWidget {
  const RebookButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SangaColors.primarySoft,
      borderRadius: SangaRadii.digit,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.sm, vertical: SangaSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: SangaSpacing.xxs,
            children: [
              const Icon(Icons.history_rounded, size: 18, color: SangaColors.primary),
              Text('Rebook', style: SangaTextStyles.caption.copyWith(color: SangaColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
