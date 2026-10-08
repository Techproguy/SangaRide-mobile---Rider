import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripChangeTiles extends StatelessWidget {
  const TripChangeTiles({
    super.key,
    required this.trip,
    required this.onAddStops,
    required this.onCancel,
    this.leading = const [],
    this.alignment = MainAxisAlignment.start,
  });

  final Trip trip;
  final VoidCallback onAddStops;
  final VoidCallback onCancel;
  final List<Widget> leading;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      spacing: SangaSpacing.sm,
      children: [
        ...leading,
        if (trip.canAddStops)
          SangaActionTile(icon: Icons.add_location_alt_rounded, label: 'Add stops', onPressed: onAddStops),
        if (trip.canChange)
          SangaActionTile(icon: Icons.close_rounded, label: 'Cancel trip', onPressed: onCancel, tone: SangaTone.danger),
      ],
    );
  }
}
