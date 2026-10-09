import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/airport/widgets/flight_status_view.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_review_cards.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/ride/widgets/trip_type_icon.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_actions.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledRideScreen extends StatefulWidget {
  const ScheduledRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<ScheduledRideScreen> createState() => _ScheduledRideScreenState();
}

class _ScheduledRideScreenState extends State<ScheduledRideScreen> {
  final _rides = Get.find<ScheduledRidesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rides.state is! ScheduledLoaded) _rides.load();
    });
  }

  ScheduledRide? get _ride {
    final state = _rides.state;
    return state is ScheduledLoaded ? state.rides.where((ride) => ride.id == widget.rideId).firstOrNull : null;
  }

  Future<void> _cancel(ScheduledRide ride) async {
    final cancelled = await cancelScheduledRide(context, _rides, ride);
    if (cancelled && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ride = _ride;
      final state = _rides.state;
      final busy = ride == null || state is! ScheduledLoaded ? null : state.actionOn(ride.id);
      return SangaPageLayout(
        title: 'Ride details',
        footer: ride == null ? null : _footer(ride, busy),
        children: [
          RideOptionAsyncState(
            isLoading: state is ScheduledLoading,
            hasFailed: state is ScheduledFailed,
            errorTitle: 'We couldn’t load this ride',
            failureMessage: switch (_rides.state) {
              ScheduledFailed(:final problem) => problem.message,
              _ => null,
            },
            onRetry: _rides.load,
            skeletonCount: 3,
            skeletonHeight: 120,
            builder: (context) => switch (_ride) {
              final shown? => _body(context, shown),
              null => SangaEmptyMessage(
                icon: Icons.event_busy_rounded,
                title: 'We can’t find that ride',
                message: 'It may already be gone.',
                actionLabel: 'Go back',
                onAction: context.pop,
              ),
            },
          ),
        ],
      );
    });
  }

  Widget _footer(ScheduledRide ride, ScheduledAction? busy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        if (ride.showsRemindAction)
          SangaButton.primary(
            label: 'Send a reminder',
            isLoading: busy == ScheduledAction.remind,
            onPressed: busy == null ? () => remindScheduledRide(_rides, ride) : null,
          ),
        SangaButton.outline(
          label: ride.isRepeat ? 'Cancel repeat ride' : 'Cancel ride',
          isLoading: busy == ScheduledAction.cancel,
          onPressed: busy == null ? () => _cancel(ride) : null,
        ),
      ],
    );
  }

  Widget _body(BuildContext context, ScheduledRide ride) {
    final airport = ride.airport;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        RideOptionRouteCard(
          pickup: Place(placeId: '', name: ride.pickup.name, address: ride.pickup.address),
          stops: const [],
          dropoff: Place(placeId: '', name: ride.dropoff.name, address: ride.dropoff.address),
          tags: [_tag(ride)],
        ),
        if (airport != null && _hasRoute(airport)) _flightCard(context, airport),
        SangaDetailList(title: 'Ride details', rows: _detailRows(context, ride)),
        SangaFareBreakdown(
          title: 'Fare',
          lines: const [],
          totalLabel: 'TOTAL ESTIMATE',
          total: SangaMoney.naira(ride.fare),
        ),
        if (airport != null)
          SangaSafetyChannelRow(
            icon: Icons.flight_rounded,
            title: 'Flight tracking',
            subtitle: 'See your flight’s current timeline',
            onTap: () => context.push(BookingRoutes.flightTrackingOf(ride.id)),
          ),
      ],
    );
  }

  bool _hasRoute(ScheduledAirport airport) => airport.origin != null && airport.destination != null;

  Widget _flightCard(BuildContext context, ScheduledAirport airport) {
    return SangaFlightCard(
      airlineName: airport.airline,
      airlineCode: airport.airlineCode,
      flightNumber: airport.flightNumber,
      originCity: airport.origin!.city,
      originCode: airport.origin!.iata,
      destinationCity: airport.destination!.city,
      destinationCode: airport.destination!.iata,
      arrivalLabel: formatRideSchedule(context, airport.estimatedArrival),
      terminalLabel: airport.terminal,
      statusLabel: airport.status.label,
      statusTone: airport.status.tone,
    );
  }

  List<SangaDetailRow> _detailRows(BuildContext context, ScheduledRide ride) {
    final airport = ride.airport;
    return [
      SangaDetailRow(
        icon: ride.tripType.icon,
        label: 'Type',
        value: ride.isRepeat ? 'Repeat ride' : ride.tripType.label,
      ),
      SangaDetailRow(
        icon: Icons.schedule_rounded,
        label: airport == null ? 'When' : 'Pick up',
        value: formatRideSchedule(context, ride.scheduledAt),
      ),
      if (ride.repeat case final rule?)
        SangaDetailRow(icon: Icons.event_repeat_rounded, label: 'Repeats', value: formatRepeatRule(context, rule)),
      if (airport != null) ..._airportRows(context, airport),
    ];
  }

  List<SangaDetailRow> _airportRows(BuildContext context, ScheduledAirport airport) {
    return [
      if (!_hasRoute(airport)) ...[
        SangaDetailRow(icon: Icons.flight_rounded, label: 'Flight', value: airport.flightNumber),
        SangaDetailRow(icon: Icons.airlines_rounded, label: 'Airline', value: airport.airline),
        if (airport.terminal case final terminal?)
          SangaDetailRow(icon: Icons.meeting_room_outlined, label: 'Terminal', value: terminal),
        SangaDetailRow(
          icon: Icons.flight_land_rounded,
          label: 'Arrives',
          value: formatRideSchedule(context, airport.estimatedArrival),
        ),
      ],
      SangaDetailRow(icon: Icons.hail_rounded, label: 'Pick up type', value: airport.pickupType.label),
      SangaDetailRow(icon: Icons.group_outlined, label: 'Passengers', value: '${airport.passengers}'),
      SangaDetailRow(icon: Icons.luggage_outlined, label: 'Luggage', value: airport.luggage),
      if (airport.assistance != Assistance.none)
        SangaDetailRow(icon: Icons.accessible_rounded, label: 'Assistance', value: airport.assistance.label),
      SangaDetailRow(icon: Icons.place_outlined, label: 'Meet point', value: airport.meetPoint),
    ];
  }

  ({String label, IconData icon}) _tag(ScheduledRide ride) {
    if (ride.isRepeat) return (label: 'Repeat', icon: Icons.event_repeat_rounded);
    if (ride.airport != null) return (label: TripType.airport.label, icon: TripType.airport.icon);
    return (label: 'Scheduled', icon: Icons.event_rounded);
  }
}
