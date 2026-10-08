import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TierCard extends StatelessWidget {
  const TierCard({
    super.key,
    required this.icon,
    required this.label,
    required this.blurb,
    required this.eta,
    required this.fare,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  static const double _tagLift = 10;

  final IconData icon;
  final String label;
  final String blurb;
  final String eta;
  final int fare;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SangaOptionCard(
          leading: SangaIconBadge(size: 40, child: Icon(icon)),
          title: label,
          subtitle: '$blurb\n$eta',
          value: SangaMoney.naira(fare),
          isSelected: isSelected,
          onTap: onTap,
        ),
        if (isRecommended)
          const Positioned(
            top: -_tagLift,
            right: SangaSpacing.md,
            child: SangaTag.success(label: 'Recommended'),
          ),
      ],
    );
  }
}
