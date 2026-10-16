import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/widgets/flight_summary_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ArrivalDetailsScreen extends StatelessWidget {
  const ArrivalDetailsScreen({super.key});

  void _confirm(BuildContext context, AirportController airport) {
    airport
      ..setPassengers(airport.draft.details.passengers)
      ..commitPickup();
    context.push(BookingRoutes.afterArrivalDetails);
  }

  @override
  Widget build(BuildContext context) {
    final airport = Get.find<AirportController>();
    return SangaPageLayout(
      title: 'Arrival details',
      footer: SangaButton.primary(label: 'Confirm', onPressed: () => _confirm(context, airport)),
      children: [
        Obx(() {
          final flight = airport.flight;
          final details = airport.draft.details;
          final limit = airport.passengerLimit;
          final passengers = math.min(details.passengers, limit);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.lg,
            children: [
              if (flight != null) FlightSummaryCard(flight: flight, airportName: airport.draft.airport?.name),
              SangaSelectField<int>(
                label: 'Luggage',
                icon: Icons.luggage_rounded,
                value: details.luggageCount,
                options: [
                  for (var count = 0; count <= AirportRules.maxLuggage; count++)
                    SangaSelectOption(count, ArrivalDetails.bagsLabel(count)),
                ],
                onChanged: airport.setLuggageCount,
              ),
              if (details.luggageCount > 0)
                SangaSelectField<LuggageSize>(
                  label: 'Bag size',
                  icon: Icons.work_rounded,
                  value: details.luggageSize,
                  options: [for (final size in LuggageSize.values) SangaSelectOption(size, size.label)],
                  onChanged: airport.setLuggageSize,
                ),
              SangaSelectField<int>(
                label: 'Passengers',
                icon: Icons.person_rounded,
                value: passengers,
                options: [
                  for (var count = 1; count <= limit; count++)
                    SangaSelectOption(count, ArrivalDetails.passengersLabelOf(count)),
                ],
                onChanged: airport.setPassengers,
              ),
              SangaSelectField<Assistance>(
                label: 'Special assistance',
                icon: Icons.accessible_rounded,
                value: details.assistance,
                options: [for (final assistance in Assistance.values) SangaSelectOption(assistance, assistance.label)],
                onChanged: airport.setAssistance,
              ),
            ],
          );
        }),
      ],
    );
  }
}
