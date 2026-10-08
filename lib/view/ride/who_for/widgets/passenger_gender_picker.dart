import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PassengerGenderPicker extends StatelessWidget {
  const PassengerGenderPicker({super.key, required this.selected, required this.onChanged});

  final PassengerGender? selected;
  final ValueChanged<PassengerGender?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SangaFieldLabel('Gender'),
        Row(
          spacing: SangaSpacing.xl,
          children: [
            for (final gender in PassengerGender.values)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: selected == gender,
                label: gender.label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(selected == gender ? null : gender),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: SangaSpacing.sm),
                    child: Row(
                      spacing: SangaSpacing.xs,
                      children: [
                        SangaRadio(isSelected: selected == gender),
                        Text(gender.label, style: SangaTextStyles.input),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
