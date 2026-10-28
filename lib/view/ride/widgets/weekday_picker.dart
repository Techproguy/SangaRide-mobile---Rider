import 'package:flutter/material.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({super.key, required this.days, required this.onToggle});

  final Set<Weekday> days;
  final void Function(Weekday day, bool isSelected) onToggle;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: BoxDecoration(
        color: SangaColors.surface,
        borderRadius: SangaRadii.field,
        border: Border.all(color: SangaColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.sm,
        children: [
          Text('When to repeat ride', style: SangaTextStyles.label),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / _columns;
              return Wrap(
                children: [
                  for (final day in Weekday.values)
                    SizedBox(
                      width: width,
                      child: _WeekdayOption(
                        label: day.label,
                        isSelected: days.contains(day),
                        onTap: () => onToggle(day, !days.contains(day)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayOption extends StatelessWidget {
  const _WeekdayOption({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SangaSpacing.xs),
          child: Row(
            spacing: SangaSpacing.xs,
            children: [
              AnimatedContainer(
                duration: SangaMotion.quick,
                curve: SangaMotion.fadeCurve,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? SangaColors.primary : SangaColors.surface,
                  border: Border.all(color: isSelected ? SangaColors.primary : SangaColors.outline),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1 : 0,
                  duration: SangaMotion.quick,
                  curve: SangaMotion.springDetail,
                  child: const Icon(Icons.check_rounded, size: 13, color: SangaColors.onPrimary),
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SangaTextStyles.input.copyWith(fontSize: 13, color: SangaColors.textMid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
