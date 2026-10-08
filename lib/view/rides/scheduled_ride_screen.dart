import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
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
            onRetry: _rides.load,
            skeletonCount: 3,
            skeletonHeight: 120,
            builder: (context) => switch (_ride) {
              final shown? => _body(context, shown),
              null => SangaInlineMessage(
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
        SangaFareBreakdown(
          title: 'Ride details',
          lines: [
            SangaFareLine('Type', ride.isRepeat ? 'Repeat ride' : ride.tripType.label),
            SangaFareLine(airport == null ? 'When' : 'Pick up', formatRideSchedule(context, ride.scheduledAt)),
            if (ride.repeat case final rule?) SangaFareLine('Repeats', formatRepeatRule(context, rule)),
            if (airport != null) ..._airportLines(context, airport),
          ],
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

  ({String label, IconData icon}) _tag(ScheduledRide ride) {
    if (ride.isRepeat) return (label: 'Repeat', icon: Icons.event_repeat_rounded);
    if (ride.airport != null) return (label: TripType.airport.label, icon: TripType.airport.icon);
    return (label: 'Scheduled', icon: Icons.event_rounded);
  }

  List<SangaFareLine> _airportLines(BuildContext context, ScheduledAirport airport) {
    return [
      SangaFareLine('Flight', airport.flightNumber),
      SangaFareLine('Airline', airport.airline),
      if (airport.terminal case final terminal?) SangaFareLine('Terminal', terminal),
      SangaFareLine('Arrives', formatRideSchedule(context, airport.estimatedArrival)),
      SangaFareLine('Pick up type', airport.pickupType.label),
      SangaFareLine('Meet point', airport.meetPoint),
      SangaFareLine('Passengers', '${airport.passengers}'),
      SangaFareLine('Luggage', airport.luggage),
      if (airport.assistance != Assistance.none) SangaFareLine('Assistance', airport.assistance.label),
    ];
  }
}
