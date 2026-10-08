import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/hourly_hours_screen.dart';
import 'package:sanga_ride/view/ride/intercity_screen.dart';
import 'package:sanga_ride/view/ride/repeat_setup_screen.dart';
import 'package:sanga_ride/view/ride/round_trip_return_screen.dart';
import 'package:sanga_ride/view/rides/scheduled_rides_screen.dart';

abstract final class BookingRoutes {
  static const String intercity = '/ride/intercity';
  static const String hourlyHours = '/ride/hours';
  static const String repeatSetup = '/ride/repeat';
  static const String roundTripReturn = '/ride/return';
  static const String scheduledRides = '/rides/scheduled';

  static String afterTripType(TripType type) => switch (type) {
    TripType.intercity => intercity,
    TripType.oneWay || TripType.roundTrip || TripType.hourly => SangaRoutes.rideOptions,
  };

  static String afterOptions(TripType type) => switch (type) {
    TripType.hourly => hourlyHours,
    TripType.oneWay || TripType.roundTrip || TripType.intercity => SangaRoutes.ridePreferences,
  };

  static const String afterHours = SangaRoutes.ridePreferences;

  static String afterFare(TripType type) => switch (type) {
    TripType.intercity => SangaRoutes.rideReview,
    TripType.oneWay || TripType.roundTrip || TripType.hourly => SangaRoutes.rideTiming,
  };

  static String afterTiming(TripType type) => switch (type) {
    TripType.roundTrip => roundTripReturn,
    TripType.oneWay || TripType.hourly || TripType.intercity => SangaRoutes.rideReview,
  };

  static final List<RouteBase> all = [
    GoRoute(path: intercity, builder: (context, state) => const IntercityScreen()),
    GoRoute(path: hourlyHours, builder: (context, state) => const HourlyHoursScreen()),
    GoRoute(path: repeatSetup, builder: (context, state) => const RepeatSetupScreen()),
    GoRoute(path: roundTripReturn, builder: (context, state) => const RoundTripReturnScreen()),
    GoRoute(path: scheduledRides, builder: (context, state) => const ScheduledRidesScreen()),
  ];
}
