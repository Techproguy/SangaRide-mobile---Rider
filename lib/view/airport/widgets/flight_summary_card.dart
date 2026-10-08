import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/widgets/flight_status_view.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FlightSummaryCard extends StatelessWidget {
  const FlightSummaryCard({super.key, required this.flight, this.airportName});

  final Flight flight;
  final String? airportName;

  String? get _terminalLabel {
    final parts = [flight.terminal?.name, airportName].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return SangaFlightCard(
      airlineName: flight.airline.name,
      airlineCode: flight.airline.code,
      flightNumber: flight.number,
      originCity: flight.origin.city,
      originCode: flight.origin.iata,
      destinationCity: flight.destination.city,
      destinationCode: flight.destination.iata,
      arrivalLabel: formatRideSchedule(context, flight.estimatedArrival),
      terminalLabel: _terminalLabel,
      statusLabel: flight.statusLabel,
      statusTone: flight.status.tone,
    );
  }
}
