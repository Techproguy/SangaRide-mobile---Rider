import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripEtaLine extends StatelessWidget {
  const TripEtaLine({super.key, required this.etaAt, this.distanceRemainingKm});

  final DateTime? etaAt;
  final double? distanceRemainingKm;

  static String labelFor(Duration remaining) {
    if (remaining < const Duration(minutes: 1)) return 'Arriving now';
    final minutes = (remaining.inSeconds / 60).ceil();
    return minutes == 1 ? '1 minute away' : '$minutes minutes away';
  }

  @override
  Widget build(BuildContext context) {
    final etaAt = this.etaAt;
    if (etaAt == null) return const SizedBox.shrink();
    final distance = distanceRemainingKm;
    return SangaCountdown(
      endsAt: etaAt,
      builder: (context, remaining) {
        final label = distance == null || remaining < const Duration(minutes: 1)
            ? labelFor(remaining)
            : '${labelFor(remaining)} · ${SangaDistance.format(distance * 1000)}';
        return Text(
          label,
          textAlign: TextAlign.end,
          style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.primary),
        );
      },
    );
  }
}
