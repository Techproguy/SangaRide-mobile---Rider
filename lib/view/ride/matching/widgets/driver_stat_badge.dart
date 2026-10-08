import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum DriverStatTone { info, positive }

class DriverStatBadge extends StatelessWidget {
  const DriverStatBadge({super.key, required this.icon, required this.label, this.tone = DriverStatTone.info});

  static const double _tile = 40;

  final IconData icon;
  final String label;
  final DriverStatTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == DriverStatTone.positive ? SangaColors.success : SangaColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.xxs,
      children: [
        Container(
          width: _tile,
          height: _tile,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: SangaRadii.field),
          child: Icon(icon, size: 20, color: color),
        ),
        Text(label, style: SangaTextStyles.tileCaption),
      ],
    );
  }
}
