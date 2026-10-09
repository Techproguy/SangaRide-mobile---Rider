import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RatingTagWrap extends StatelessWidget {
  const RatingTagWrap({super.key, required this.tags, required this.selected, required this.onToggle});

  final List<RatingTag> tags;
  final Set<RatingTag> selected;
  final ValueChanged<RatingTag> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
          alignment: WrapAlignment.center,
          spacing: SangaSpacing.sm,
          runSpacing: SangaSpacing.xs,
          children: [
            for (final tag in tags)
              SangaChoiceChip(label: tag.label, isSelected: selected.contains(tag), onSelected: (_) => onToggle(tag)),
          ],
        )
        .animate()
        .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
        .moveY(begin: SangaSpacing.xs, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock);
  }
}
