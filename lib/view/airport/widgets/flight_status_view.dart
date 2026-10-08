import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

extension FlightStatusView on FlightStatus {
  SangaFlightTone get tone => switch (this) {
    FlightStatus.scheduled => SangaFlightTone.onTime,
    FlightStatus.delayed => SangaFlightTone.delayed,
    FlightStatus.landed => SangaFlightTone.landed,
    FlightStatus.cancelled || FlightStatus.diverted => SangaFlightTone.cancelled,
  };

  String get label => switch (this) {
    FlightStatus.scheduled => 'On time',
    FlightStatus.delayed => 'Delayed',
    FlightStatus.landed => 'Landed',
    FlightStatus.cancelled => 'Cancelled',
    FlightStatus.diverted => 'Diverted',
  };
}

extension FlightView on Flight {
  String get statusLabel =>
      status == FlightStatus.delayed && delay > Duration.zero ? 'Delayed ${formatRideDuration(delay)}' : status.label;
}

class FlightStatusTag extends StatelessWidget {
  const FlightStatusTag({super.key, required this.status, this.label});

  final FlightStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? status.label;
    return switch (status) {
      FlightStatus.scheduled => SangaTag.success(label: text, icon: Icons.schedule_rounded),
      FlightStatus.delayed => SangaTag.warning(label: text, icon: Icons.schedule_rounded),
      FlightStatus.landed => SangaTag.success(label: text, icon: Icons.flight_land_rounded),
      FlightStatus.cancelled || FlightStatus.diverted => SangaTag.urgent(label: text, icon: Icons.block_rounded),
    };
  }
}
