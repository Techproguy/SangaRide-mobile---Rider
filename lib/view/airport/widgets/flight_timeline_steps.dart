import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaFlightStep> flightTimelineSteps(BuildContext context, FlightTracking tracking) {
  return [for (final event in tracking.events) _step(context, event, tracking.flight)];
}

SangaFlightStep _step(BuildContext context, FlightEvent event, Flight flight) {
  final isDisruptedLanding = event.type == FlightEventType.landed && flight.status.cannotBeBooked;
  final state = isDisruptedLanding
      ? SangaTimelineState.alert
      : switch (event.state) {
          FlightEventState.done => SangaTimelineState.done,
          FlightEventState.current => SangaTimelineState.current,
          FlightEventState.pending => SangaTimelineState.pending,
        };
  final at = event.at;
  final isDone = event.state == FlightEventState.done;
  if (event.type == FlightEventType.scheduledArrival) {
    return SangaFlightStep(
      label: formatRideSchedule(context, at ?? flight.scheduledArrival),
      time: 'Scheduled arrival',
      state: state,
    );
  }
  final time = switch (event.state) {
    FlightEventState.done when at != null => formatRideClock(context, at),
    FlightEventState.current when at != null && event.type == FlightEventType.landed =>
      'Expected ${formatRideClock(context, at)}',
    FlightEventState.current => 'Up next',
    _ => null,
  };
  return SangaFlightStep(label: _label(event.type, flight.status, isDone), time: time, state: state);
}

String _label(FlightEventType type, FlightStatus status, bool isDone) => switch (type) {
  FlightEventType.scheduledArrival => 'Scheduled arrival',
  FlightEventType.landed => switch (status) {
    FlightStatus.cancelled => 'Flight cancelled',
    FlightStatus.diverted => 'Flight diverted',
    _ => isDone ? 'Landed' : 'Landing',
  },
  FlightEventType.baggageClaimed => isDone ? 'Baggage claimed' : 'Baggage claim',
  FlightEventType.atMeetPoint => isDone ? 'Waiting for you at meeting point' : 'Arrival at meet point',
  FlightEventType.met => isDone ? 'Met passengers at meeting point' : 'Driver pick up',
};
