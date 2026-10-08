import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MatchCheckRows extends StatelessWidget {
  const MatchCheckRows({super.key});

  static const List<(IconData, String)> checks = [
    (Icons.person_rounded, 'Driver name matches'),
    (Icons.directions_car_rounded, 'Vehicle make and colour match'),
    (Icons.pin_rounded, 'Plate number matches'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        for (final (icon, label) in checks)
          Row(
            spacing: SangaSpacing.sm,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: SangaColors.fill, borderRadius: SangaRadii.digit),
                child: Icon(icon, size: 16, color: SangaColors.textPrimary),
              ),
              Expanded(child: Text(label, style: SangaTextStyles.input)),
            ],
          ),
      ],
    );
  }
}
