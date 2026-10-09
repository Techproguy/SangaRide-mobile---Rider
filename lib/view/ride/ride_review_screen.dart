import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/airport/widgets/airport_review_lines.dart';
import 'package:sanga_ride/view/airport/widgets/flight_summary_card.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_review_cards.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/ride/widgets/scheduled_success.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/ride_for_summary_row.dart';
import 'package:sanga_ride/view/ride/widgets/trip_type_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideReviewScreen extends StatefulWidget {
  const RideReviewScreen({super.key});

  @override
  State<RideReviewScreen> createState() => _RideReviewScreenState();
}

class _RideReviewScreenState extends State<RideReviewScreen> {
  final _match = Get.find<RideMatchController>();

  @override
  void dispose() {
    if (_match.isLive) scheduleMicrotask(_match.abandon);
    super.dispose();
  }

  Future<void> _submit(RideRequestController ride) async {
    if (ride.isScheduledBooking) return _schedule(ride);
    await startMatching(context);
  }

  Future<void> _schedule(RideRequestController ride) async {
    final outcome = await ride.scheduleBooking();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case ScheduleRejected(:final problem):
        if (problem == BookingProblem.quoteExpired) unawaited(ride.refreshQuote());
        SangaToast.show(problem.message, tone: SangaToastTone.error);
      case ScheduleUnconfirmed():
        await _askAboutUnconfirmed(ride);
      case ScheduleSucceeded(:final booking):
        await _celebrate(ride, booking);
    }
  }

  Future<void> _askAboutUnconfirmed(RideRequestController ride) async {
    final tryAgain = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      icon: Icons.sync_problem_rounded,
      title: 'We’re not sure it booked',
      message: 'Try again and we won’t book it twice. Or check your scheduled rides first.',
      actionLabel: 'Try again',
      secondaryLabel: 'View scheduled rides',
    );
    if (!mounted) return;
    if (tryAgain) return _schedule(ride);
    unawaited(context.push(BookingRoutes.scheduledRides));
  }

  Future<void> _celebrate(RideRequestController ride, ScheduledBooking booking) async {
    final first = formatRideMoment(context, booking.scheduledAt);
    final (title, message) = switch ((ride.timing, ride.tripType)) {
      (RideTiming.repeat, _) => ('Repeat ride booked', 'Your first ride is $first.'),
      (_, TripType.intercity) => ('Intercity trip booked', 'We’ll pick you up $first.'),
      _ => ('Ride scheduled', 'Your ride is booked for $first.'),
    };
    await showScheduledSuccess(context, title: title, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return Obx(() => PopScope(canPop: !_match.isStarting && !ride.isScheduling, child: _layout(context, ride)));
  }

  Widget _layout(BuildContext context, RideRequestController ride) {
    return SangaPageLayout(
      title: 'Review your ride',
      footer: Obx(() => _footer(ride)),
      children: [
        Obx(() {
          final pricing = ride.pricing;
          final price = ride.price;
          return Column(
            spacing: SangaSpacing.md,
            children: [
              if (ride.airportBooking case final booking? when ride.tripType == TripType.airport)
                FlightSummaryCard(flight: booking.flight, airportName: booking.airport.name),
              RideOptionRouteCard(
                pickup: ride.pickup,
                stops: ride.stops.toList(),
                dropoff: ride.dropoff,
                tags: _tags(ride),
              ),
              if (ride.option case final option?) _vehicleCard(ride, option),
              const RideForSummaryRow(),
              if (pricing != null && price != null)
                SangaFareBreakdown(
                  title: 'Ride details',
                  lines: [
                    SangaFareLine('Pricing', pricing.label),
                    ..._tripLines(context, ride),
                    SangaFareLine('Preferences', _preferencesLabel(ride.preferences)),
                    if (ride.preferences.driverLanguage != const RidePreferences().driverLanguage)
                      SangaFareLine('Driver language', ride.preferences.driverLanguage),
                  ],
                  totalLabel: ride.timing == RideTiming.repeat ? 'ESTIMATE PER RIDE' : 'TOTAL ESTIMATE',
                  total: SangaMoney.naira(price),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _footer(RideRequestController ride) {
    final starting = _match.state;
    final isBusy = _match.isStarting || ride.isScheduling;
    final isChecking = starting is MatchStarting && starting.isChecking;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SangaButton.primary(
          label: _submitLabel(ride),
          isLoading: isBusy,
          onPressed: ride.estimate == null || ride.pricing == null || _match.isLive || !ride.isReadyToReview || isBusy
              ? null
              : () => _submit(ride),
        ),
        if (isChecking)
          const Padding(
            padding: EdgeInsets.only(top: SangaSpacing.sm),
            child: Text(
              'Making sure your request went through…',
              textAlign: TextAlign.center,
              style: SangaTextStyles.statusMessage,
            ),
          ),
        if (isBusy) SangaBusyEscape(onClose: () => context.go(SangaRoutes.home)),
      ],
    );
  }

  String _submitLabel(RideRequestController ride) =>
      ride.tripType == TripType.airport ? 'Book airport pickup' : _timingLabel(ride);

  String _timingLabel(RideRequestController ride) => switch (ride.timing) {
    RideTiming.repeat => 'Book repeat ride',
    RideTiming.later => 'Schedule ride',
    RideTiming.now => ride.tripType.isAlwaysScheduled ? 'Schedule ride' : 'Find a driver',
  };

  List<({String label, IconData icon})> _tags(RideRequestController ride) => [
    if (ride.tripType != TripType.oneWay) (label: ride.tripType.label, icon: ride.tripType.icon),
    if (ride.timing == RideTiming.repeat) (label: 'Repeat', icon: Icons.event_repeat_rounded),
    if (ride.timing == RideTiming.later && !ride.tripType.isAlwaysScheduled)
      (label: 'Scheduled', icon: Icons.event_rounded),
  ];

  Widget _vehicleCard(RideRequestController ride, RideOption option) => SangaVehicleCard(
    image: option.category.image,
    name: option.name,
    description: option.description,
    seats: option.seats,
    price: ride.rateLabel(option),
    isSelected: true,
  );

  List<SangaFareLine> _tripLines(BuildContext context, RideRequestController ride) {
    final returnAt = ride.returnAt;
    final rule = ride.repeatRule;
    final scheduledAt = ride.scheduledAt;
    final airport = ride.airportBooking;
    if (ride.tripType == TripType.airport) return airport == null ? const [] : airportReviewLines(context, airport);
    return [
      SangaFareLine('Trip', ride.tripType.label),
      if (ride.tripType == TripType.hourly) ...[
        SangaFareLine('Duration', _hoursLabel(ride.hours)),
        SangaFareLine('Stay with me', ride.staysWithRider ? 'Yes' : 'No'),
      ],
      if (ride.tripType == TripType.intercity && ride.fromCity != null && ride.toCity != null)
        SangaFareLine('Cities', '${ride.fromCity!.name} to ${ride.toCity!.name}'),
      switch (ride.timing) {
        RideTiming.repeat when rule != null => SangaFareLine('Repeats', formatRepeatRule(context, rule)),
        RideTiming.repeat => const SangaFareLine('Repeats', 'Not set'),
        RideTiming.later when scheduledAt != null => SangaFareLine(
          ride.tripType == TripType.intercity ? 'Departure' : 'When',
          formatRideSchedule(context, scheduledAt),
        ),
        RideTiming.later || RideTiming.now => SangaFareLine('When', RideTiming.now.label),
      },
      if (rule?.firstRideAfter(BookingClock.now()) case final first?)
        SangaFareLine('First ride', formatRideSchedule(context, first)),
      if (returnAt != null && ride.tripType == TripType.roundTrip)
        SangaFareLine('Return', formatRideSchedule(context, returnAt)),
    ];
  }

  String _hoursLabel(int hours) => hours == 1 ? '1 hour' : '$hours hours';

  String _preferencesLabel(RidePreferences preferences) {
    final labels = preferences.activeLabels;
    return labels.isEmpty ? 'None' : labels.join(', ');
  }
}
