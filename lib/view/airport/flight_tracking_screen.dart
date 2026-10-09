import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/flight_tracking_controller.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/airport/widgets/flight_summary_card.dart';
import 'package:sanga_ride/view/airport/widgets/flight_timeline_steps.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/rides/widgets/cancel_scheduled_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FlightTrackingScreen extends StatefulWidget {
  const FlightTrackingScreen({super.key, required this.rideId, this.isTrip = false});

  final String rideId;
  final bool isTrip;

  @override
  State<FlightTrackingScreen> createState() => _FlightTrackingScreenState();
}

class _FlightTrackingScreenState extends State<FlightTrackingScreen> {
  final _tracking = Get.find<FlightTrackingController>();
  final _rides = Get.find<ScheduledRidesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tracking.open(widget.rideId));
  }

  @override
  void dispose() {
    scheduleMicrotask(_tracking.close);
    super.dispose();
  }

  Future<void> _notify() async {
    final problem = await _tracking.notifyDriver();
    if (!mounted) return;
    if (problem != null) return SangaToast.show(problem.message, tone: SangaToastTone.error);
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'Your driver has been reminded',
      actionLabel: 'Done',
    );
  }

  Future<void> _cancel(FlightTracking tracking) async {
    if (widget.isTrip) {
      unawaited(context.push(TripRoutes.cancelOf(widget.rideId)));
      return;
    }
    final confirmed = await showCancelScheduledSheet(
      context: context,
      isRepeat: false,
      whenLabel: formatRideSchedule(context, tracking.pickupAt),
    );
    if (!confirmed || !mounted) return;
    if (_rides.state is! ScheduledLoaded) await _rides.load();
    final problem = await _rides.cancel(widget.rideId);
    if (!mounted) return;
    if (problem == null) {
      SangaToast.show('Ride cancelled. You won’t be charged.', tone: SangaToastTone.success);
      context.pop();
    } else {
      SangaToast.show(problem.message, tone: SangaToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SangaPageHeader(title: 'Flight tracking'),
              Expanded(
                child: RefreshIndicator(
                  color: SangaColors.primary,
                  onRefresh: _tracking.reload,
                  child: Obx(
                    () => ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: SangaMotion.pagePhysics),
                      padding: const EdgeInsets.fromLTRB(
                        SangaSpacing.gutter,
                        SangaSpacing.md,
                        SangaSpacing.gutter,
                        SangaSpacing.xl,
                      ),
                      children: [_body(context, _tracking.state)],
                    ),
                  ),
                ),
              ),
              Obx(() {
                final tracking = _tracking.tracking;
                final footer = tracking == null ? null : _footer(tracking);
                if (footer == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, 0, SangaSpacing.gutter, SangaSpacing.md),
                  child: footer,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FlightTrackingState state) {
    return switch (state) {
      FlightTrackingLoading() => const SangaSkeleton.heights([120, 72, 160]),
      FlightTrackingFailed(:final reason) =>
        reason.canRetry
            ? SangaFailureMessage(title: reason.title, message: reason.message, onRetry: _tracking.retry)
            : SangaEmptyMessage(
                icon: Icons.flight_land_rounded,
                title: reason.title,
                message: reason.message,
                actionLabel: 'Go back',
                onAction: context.pop,
              ),
      FlightTrackingReady(:final tracking) => _ready(context, tracking),
    };
  }

  Widget _ready(BuildContext context, FlightTracking tracking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        FlightSummaryCard(flight: tracking.flight),
        ..._notices(context, tracking),
        SangaDetailList(
          title: 'Your pick up',
          rows: [
            SangaDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Pick up',
              value: formatRideSchedule(context, tracking.pickupAt),
            ),
            if (tracking.pickupAdjusted)
              SangaDetailRow(
                icon: Icons.update_rounded,
                label: 'Moved',
                value: '${formatRideDuration(tracking.flight.delay)} later, because your flight is running late',
              ),
          ],
        ),
        const SizedBox(height: SangaSpacing.xs),
        const SangaSectionHeader('Flight timeline'),
        SangaFlightTimeline(entries: flightTimelineSteps(context, tracking)),
      ],
    );
  }

  List<Widget> _notices(BuildContext context, FlightTracking tracking) {
    final freeUntil = tracking.cancellation?.freeUntil;
    return switch (tracking.flight.status) {
      FlightStatus.cancelled => [
        SangaNotice(
          message: freeUntil == null
              ? 'Your flight was cancelled, so there’s nothing to pick up right now.'
              : 'Your flight was cancelled. You can cancel this ride for free until ${formatRideSchedule(context, freeUntil)}.',
        ),
      ],
      FlightStatus.diverted => const [
        SangaNotice(
          message: 'Your flight was diverted and won’t land here. Check with your airline for where it lands.',
        ),
      ],
      _ => const [],
    };
  }

  Widget? _footer(FlightTracking tracking) {
    if (tracking.flight.status == FlightStatus.cancelled && tracking.cancellation != null) {
      final state = _rides.state;
      final busy = state is ScheduledLoaded && state.actionOn(widget.rideId) == ScheduledAction.cancel;
      return SangaButton.danger(
        label: widget.isTrip ? 'Cancel this ride' : 'Cancel ride for free',
        isLoading: busy,
        onPressed: () => _cancel(tracking),
      );
    }
    if (widget.isTrip || tracking.isDisrupted) return null;
    final notify = _tracking.notifyState;
    final caption = switch (notify) {
      NotifySent(:final at) => 'You reminded your driver at ${formatRideClock(context, at)}.',
      _ when !tracking.hasLanded => 'You can notify your driver once your flight has landed.',
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        SangaButton.primary(
          label: 'Notify your driver',
          isLoading: notify is NotifySending,
          onPressed: tracking.hasLanded && notify is NotifyIdle ? _notify : null,
        ),
        if (caption != null) Text(caption, textAlign: TextAlign.center, style: SangaTextStyles.caption),
      ],
    );
  }
}
