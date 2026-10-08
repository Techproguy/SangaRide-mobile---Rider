import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/rides/widgets/cancel_scheduled_sheet.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_ride_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen> {
  final _rides = Get.find<ScheduledRidesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rides.load());
  }

  Future<void> _cancel(ScheduledRide ride) async {
    final confirmed = await showCancelScheduledSheet(
      context: context,
      isRepeat: ride.isRepeat,
      whenLabel: formatRideSchedule(context, ride.scheduledAt),
    );
    if (!confirmed || !mounted) return;
    final problem = await _rides.cancel(ride.id);
    if (problem == null) {
      Toast.success(ride.isRepeat ? 'Repeat ride cancelled.' : 'Ride cancelled.');
    } else {
      Toast.error(problem.message);
    }
  }

  Future<void> _remind(ScheduledRide ride) async {
    final problem = await _rides.remind(ride.id);
    if (problem == null) {
      Toast.success('Done. We’ll remind you before your ride.');
    } else {
      Toast.error(problem.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Scheduled rides',
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _rides.state is ScheduledLoading,
            hasFailed: _rides.state is ScheduledFailed,
            errorTitle: 'We couldn’t load your scheduled rides',
            onRetry: _rides.load,
            skeletonCount: 3,
            skeletonHeight: 190,
            builder: _buildList,
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final state = _rides.state;
    if (state is! ScheduledLoaded) return const SizedBox.shrink();
    if (state.rides.isEmpty) {
      return SangaInlineMessage(
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
    return ScheduledRideCard(
      ride: ride,
      whenLabel: formatRideSchedule(context, ride.scheduledAt),
      tagLabel: _tagLabel(ride),
      repeatLabel: rule == null ? null : formatRepeatRule(context, rule),
      reminderLabel: reminderAt == null ? null : 'Reminder at ${formatRideClock(context, reminderAt)}',
      busyAction: state.actionOn(ride.id),
      onCancel: () => _cancel(ride),
      onRemind: ride.showsRemindAction ? () => _remind(ride) : null,
    );
  }

  String _tagLabel(ScheduledRide ride) {
    if (ride.isRepeat) return 'Repeat';
    return ride.tripType == TripType.oneWay ? 'Scheduled' : ride.tripType.label;
  }
}
