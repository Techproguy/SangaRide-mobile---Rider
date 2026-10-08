import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SafetyCheckRow extends StatelessWidget {
  const SafetyCheckRow({super.key, required this.label, required this.isConfirmed});

  final String label;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: SangaSpacing.sm,
      children: [
        SangaCheckbox(isChecked: isConfirmed, size: 18),
        Expanded(child: Text(label, style: SangaTextStyles.input)),
        Text(
          isConfirmed ? 'Confirmed' : 'Pending',
          style: SangaTextStyles.cardSubtitle.copyWith(
            color: isConfirmed ? SangaColors.success : SangaColors.textMuted,
          ),
        ),
      ],
    );
  }
}
