import 'package:flutter/widgets.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride/view/rides/widgets/cancel_scheduled_sheet.dart';

Future<bool> cancelScheduledRide(BuildContext context, ScheduledRidesController rides, ScheduledRide ride) async {
  final confirmed = await showCancelScheduledSheet(
    context: context,
    isRepeat: ride.isRepeat,
    whenLabel: formatRideSchedule(context, ride.scheduledAt),
  );
  if (!confirmed || !context.mounted) return false;
  final problem = await rides.cancel(ride.id);
  if (problem == null) {
    Toast.success(ride.isRepeat ? 'Repeat ride cancelled.' : 'Ride cancelled.');
    return true;
  }
  Toast.error(problem.message);
  return false;
}

Future<void> remindScheduledRide(ScheduledRidesController rides, ScheduledRide ride) async {
  final problem = await rides.remind(ride.id);
  if (problem == null) {
    Toast.success('Done. We’ll remind you before your ride.');
  } else {
    Toast.error(problem.message);
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
