import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReportCategoryChips extends StatelessWidget {
  const ReportCategoryChips({super.key, required this.selected, required this.onSelected});

  final ReportCategory? selected;
  final ValueChanged<ReportCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        const SangaFieldLabel('What kind of issue?', isRequired: true),
        Wrap(
          spacing: SangaSpacing.xs,
          runSpacing: SangaSpacing.xs,
          children: [
            for (final category in ReportCategory.values)
              SangaChoiceChip(
                label: category.label,
                isSelected: category == selected,
                onSelected: (_) => onSelected(category),
              ),
          ],
        ),
      ],
    );
  }
}
