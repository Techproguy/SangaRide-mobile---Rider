import 'package:flutter/widgets.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/rides/widgets/cancel_scheduled_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaToast, SangaToastTone;

Future<bool> cancelScheduledRide(BuildContext context, ScheduledRidesController rides, ScheduledRide ride) async {
  final confirmed = await showCancelScheduledSheet(
    context: context,
    isRepeat: ride.isRepeat,
    whenLabel: formatRideSchedule(context, ride.scheduledAt),
  );
  if (!confirmed || !context.mounted) return false;
  final problem = await rides.cancel(ride.id);
  if (problem == null) {
    SangaToast.show(ride.isRepeat ? 'Repeat ride cancelled.' : 'Ride cancelled.', tone: SangaToastTone.success);
    return true;
  }
  SangaToast.show(problem.message, tone: SangaToastTone.error);
  return false;
}

Future<void> remindScheduledRide(ScheduledRidesController rides, ScheduledRide ride) async {
  final problem = await rides.remind(ride.id);
  if (problem == null) {
    SangaToast.show('Done. We’ll remind you before your ride.', tone: SangaToastTone.success);
  } else {
    SangaToast.show(problem.message, tone: SangaToastTone.error);
  }
}

String airportCardLabel(BuildContext context, ScheduledAirport airport) {
  final clock = formatRideClock(context, airport.estimatedArrival);
  final detail = switch (airport.status) {
    FlightStatus.scheduled => 'lands $clock',
    FlightStatus.delayed => 'delayed, lands $clock',
    FlightStatus.landed => 'landed',
    FlightStatus.cancelled => 'cancelled',
    FlightStatus.diverted => 'diverted',
  };
  return '${airport.flightNumber} · $detail';
}
