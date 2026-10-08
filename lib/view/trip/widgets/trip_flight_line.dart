import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/widgets/flight_status_view.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripFlightLine extends StatelessWidget {
  const TripFlightLine({super.key, required this.airport, required this.onTap});

  final TripAirport airport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SangaSpacing.md),
      child: Material(
        color: SangaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: SangaColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.sm, vertical: SangaSpacing.xs),
            child: Row(
              spacing: SangaSpacing.sm,
              children: [
                const Icon(Icons.flight_rounded, size: 18, color: SangaColors.primary),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: airport.flightNumber,
                      style: SangaTextStyles.cardTitle,
                      children: [TextSpan(text: ' · ${airport.meetPoint}', style: SangaTextStyles.cardSubtitle)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FlightStatusTag(status: airport.status),
                const Icon(Icons.chevron_right_rounded, size: 20, color: SangaColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
