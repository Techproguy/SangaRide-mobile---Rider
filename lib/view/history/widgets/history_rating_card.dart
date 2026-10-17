import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryRatingCard extends StatelessWidget {
  const HistoryRatingCard({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return SangaSectionCard(
      title: 'Your rating',
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Center(child: SangaStarRating(rating: stars.toDouble(), size: 26)),
        ),
      ],
    );
  }
}
