import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BookingNote extends StatelessWidget {
  const BookingNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SangaColors.primaryWash, borderRadius: SangaRadii.field),
      child: Padding(
        padding: const EdgeInsets.all(SangaSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.sm,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: SangaColors.primary),
            Expanded(
              child: Text(message, style: SangaTextStyles.body.copyWith(color: SangaColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
