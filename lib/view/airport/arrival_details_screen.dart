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
              SangaCounterField(
                label: 'Luggage',
                icon: Icons.luggage_rounded,
                valueLabel: details.luggageLabel,
                value: details.luggageCount,
                max: AirportRules.maxLuggage,
                onChanged: airport.setLuggageCount,
              ),
              if (details.luggageCount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SangaSpacing.xs,
                  children: [
                    const SangaFieldLabel('Bag size'),
                    SangaChoiceChips<LuggageSize>(
                      options: [for (final size in LuggageSize.values) SangaSelectOption(size, size.label)],
                      value: details.luggageSize,
                      onChanged: airport.setLuggageSize,
                    ),
                  ],
                ),
              SangaCounterField(
                label: 'Passengers',
                icon: Icons.person_rounded,
                valueLabel: passengers == 1 ? '1 passenger' : '$passengers passengers',
                value: passengers,
                min: 1,
                max: limit,
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
