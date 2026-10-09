import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_actions.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_ride_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledRidesBody extends StatefulWidget {
  const ScheduledRidesBody({super.key});

  @override
  State<ScheduledRidesBody> createState() => _ScheduledRidesBodyState();
}

class _ScheduledRidesBodyState extends State<ScheduledRidesBody> {
  final _rides = Get.find<ScheduledRidesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rides.load());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RideOptionAsyncState(
        isLoading: _rides.state is ScheduledLoading,
        hasFailed: _rides.state is ScheduledFailed,
        errorTitle: 'We couldn’t load your scheduled rides',
        failureMessage: switch (_rides.state) {
          ScheduledFailed(:final problem) => problem.message,
          _ => null,
        },
        onRetry: _rides.load,
        skeletonCount: 3,
        skeletonHeight: 190,
        builder: _buildList,
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final state = _rides.state;
    if (state is! ScheduledLoaded) return const SizedBox.shrink();
    if (state.rides.isEmpty) {
      return SangaEmptyMessage(
        icon: Icons.event_available_rounded,
        title: 'Nothing scheduled yet',
        message: 'Plan a ride ahead and it will show up here.',
        actionLabel: 'Plan a ride',
        onAction: () => context.go(SangaRoutes.home),
      );
    }
    return Column(spacing: SangaSpacing.md, children: [for (final ride in state.rides) _card(context, ride, state)]);
  }

  Widget _card(BuildContext context, ScheduledRide ride, ScheduledLoaded state) {
    final rule = ride.repeat;
    final reminderAt = ride.reminderAt;
    final airport = ride.airport;
    return ScheduledRideCard(
      ride: ride,
      whenLabel: formatRideSchedule(context, ride.scheduledAt),
      tagLabel: _tagLabel(ride),
      repeatLabel: rule == null ? null : formatRepeatRule(context, rule),
      reminderLabel: reminderAt == null ? null : 'Reminder at ${formatRideClock(context, reminderAt)}',
      busyAction: state.actionOn(ride.id),
      flightLabel: airport == null ? null : airportCardLabel(context, airport),
      onTap: () => context.push(BookingRoutes.scheduledRideOf(ride.id)),
      onCancel: () => cancelScheduledRide(context, _rides, ride),
      onRemind: ride.showsRemindAction ? () => remindScheduledRide(_rides, ride) : null,
    );
  }

  String _tagLabel(ScheduledRide ride) {
    if (ride.isRepeat) return 'Repeat';
    if (ride.tripType == TripType.airport) return TripType.airport.label;
    return ride.tripType == TripType.oneWay ? 'Scheduled' : ride.tripType.label;
  }
}
