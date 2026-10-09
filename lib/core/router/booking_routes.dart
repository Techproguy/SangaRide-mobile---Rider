import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/airport_pickup_screen.dart';
import 'package:sanga_ride/view/airport/airport_select_screen.dart';
import 'package:sanga_ride/view/airport/arrival_details_screen.dart';
import 'package:sanga_ride/view/airport/flight_details_screen.dart';
import 'package:sanga_ride/view/airport/flight_found_screen.dart';
import 'package:sanga_ride/view/airport/flight_tracking_screen.dart';
import 'package:sanga_ride/view/ride/hourly_hours_screen.dart';
import 'package:sanga_ride/view/ride/intercity_screen.dart';
import 'package:sanga_ride/view/ride/repeat_setup_screen.dart';
import 'package:sanga_ride/view/ride/round_trip_return_screen.dart';
import 'package:sanga_ride/view/rides/scheduled_ride_screen.dart';
import 'package:sanga_ride/view/rides/scheduled_rides_screen.dart';

abstract final class BookingRoutes {
  static const String intercity = '/ride/intercity';
  static const String hourlyHours = '/ride/hours';
  static const String repeatSetup = '/ride/repeat';
  static const String roundTripReturn = '/ride/return';
  static const String scheduledRides = '/rides/scheduled';
  static const String scheduledRide = '/rides/scheduled/:id';
  static const String airportSelect = '/ride/airport';
  static const String airportDestination = '/ride/airport/to';
  static const String airportFlight = '/ride/airport/flight';
  static const String airportFound = '/ride/airport/found';
  static const String airportArrival = '/ride/airport/arrival';
  static const String airportPickup = '/ride/airport/pickup';
  static const String flightTracking = '/ride/flight/:id';
  static const String tripSource = 'trip';

  static String scheduledRideOf(String id) => scheduledRide.replaceFirst(':id', id);

  static String flightTrackingOf(String id, {bool isTrip = false}) {
    final path = flightTracking.replaceFirst(':id', id);
    return isTrip ? '$path?source=$tripSource' : path;
  }

  static const String afterAirportSelect = airportFlight;
  static const String afterFlightDetails = airportFound;
  static const String afterFlightFound = airportArrival;
  static const String afterArrivalDetails = airportPickup;
  static const String afterAirportPickup = SangaRoutes.rideOptions;

  static String afterTripType(TripType type) => switch (type) {
    TripType.intercity => intercity,
    TripType.airport => airportSelect,
    TripType.delivery => DeliveryRoutes.tier,
    TripType.oneWay || TripType.roundTrip || TripType.hourly => SangaRoutes.rideOptions,
  };

  static String afterRoute(TripType type) => switch (type) {
    TripType.delivery => DeliveryRoutes.tier,
    TripType.oneWay ||
    TripType.roundTrip ||
    TripType.hourly ||
    TripType.intercity ||
    TripType.airport => SangaRoutes.tripType,
  };

  static String afterOptions(TripType type) => switch (type) {
    TripType.hourly => hourlyHours,
    TripType.delivery => DeliveryRoutes.review,
    TripType.oneWay || TripType.roundTrip || TripType.intercity || TripType.airport => SangaRoutes.ridePreferences,
  };

  static const String afterHours = SangaRoutes.ridePreferences;

  static String afterFare(TripType type) => switch (type) {
    TripType.intercity || TripType.airport => SangaRoutes.rideReview,
    TripType.delivery => DeliveryRoutes.review,
    TripType.oneWay || TripType.roundTrip || TripType.hourly => SangaRoutes.rideTiming,
  };

  static String afterTiming(TripType type) => switch (type) {
    TripType.roundTrip => roundTripReturn,
    TripType.delivery => DeliveryRoutes.review,
    TripType.oneWay || TripType.hourly || TripType.intercity || TripType.airport => SangaRoutes.rideReview,
  };

  static final List<RouteBase> all = [
    GoRoute(path: intercity, builder: (context, state) => const IntercityScreen()),
    GoRoute(path: hourlyHours, builder: (context, state) => const HourlyHoursScreen()),
    GoRoute(path: repeatSetup, builder: (context, state) => const RepeatSetupScreen()),
    GoRoute(path: roundTripReturn, builder: (context, state) => const RoundTripReturnScreen()),
    GoRoute(path: scheduledRides, builder: (context, state) => const ScheduledRidesScreen()),
    GoRoute(
      path: scheduledRide,
      builder: (context, state) => ScheduledRideScreen(rideId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: airportSelect,
      builder: (context, state) => const AirportSelectScreen(mode: AirportSelectMode.pickUp),
    ),
    GoRoute(
      path: airportDestination,
      builder: (context, state) => const AirportSelectScreen(mode: AirportSelectMode.dropOff),
    ),
    GoRoute(path: airportFlight, builder: (context, state) => const FlightDetailsScreen()),
    GoRoute(path: airportFound, builder: (context, state) => const FlightFoundScreen()),
    GoRoute(path: airportArrival, builder: (context, state) => const ArrivalDetailsScreen()),
    GoRoute(path: airportPickup, builder: (context, state) => const AirportPickupScreen()),
    GoRoute(
      path: flightTracking,
      builder: (context, state) => FlightTrackingScreen(
        rideId: state.pathParameters['id']!,
        isTrip: state.uri.queryParameters['source'] == tripSource,
      ),
    ),
  ];
}
