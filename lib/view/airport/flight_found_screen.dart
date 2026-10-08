import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/widgets/flight_summary_card.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FlightFoundScreen extends StatelessWidget {
  const FlightFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final airport = Get.find<AirportController>();
    return Obx(() {
      final flight = airport.flight;
      return SangaPageLayout(
        title: 'Flight found',
        footer: SangaButton.primary(
          label: 'Confirm',
          onPressed: flight == null || flight.status.cannotBeBooked
              ? null
              : () => context.push(BookingRoutes.afterFlightFound),
        ),
        children: [
          if (flight == null)
            SangaInlineMessage(
              title: 'We lost track of your flight',
              message: 'Go back and check your flight details again.',
              actionLabel: 'Go back',
              onAction: context.pop,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.md,
              children: [
                FlightSummaryCard(flight: flight, airportName: airport.draft.airport?.name),
                _notice(flight),
              ],
            ),
        ],
      );
    });
  }

  Widget _notice(Flight flight) {
    return switch (flight.status) {
      FlightStatus.scheduled => const SangaNotice(
        message: 'We’ll track your flight and adjust your pick up time if anything changes.',
        tone: SangaTone.neutral,
        icon: Icons.info_outline_rounded,
      ),
      FlightStatus.delayed => SangaNotice(
        message:
            'Your flight is running about ${formatRideDuration(flight.delay)} late. We’ll plan your pick up around the new time.',
        tone: SangaTone.neutral,
        icon: Icons.schedule_rounded,
      ),
      FlightStatus.landed => const SangaNotice(
        message: 'Your flight has landed. We’ll start looking for your driver as soon as you book.',
        tone: SangaTone.neutral,
        icon: Icons.flight_land_rounded,
      ),
      FlightStatus.cancelled => const SangaNotice(
        message:
            'This flight has been cancelled, so we can’t plan a pick up. Check with your airline for a new flight.',
      ),
      FlightStatus.diverted => const SangaNotice(
        message: 'This flight was diverted and won’t land here. Check with your airline for the new landing airport.',
      ),
    };
  }
}
