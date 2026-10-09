import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/trip/cancel/cancel_screen.dart';
import 'package:sanga_ride/view/trip/stops/add_stop_screen.dart';
import 'package:sanga_ride/view/trip/trip_chat_screen.dart';
import 'package:sanga_ride/view/trip/trip_details_screen.dart';
import 'package:sanga_ride/view/trip/trip_screen.dart';
import 'package:sanga_ride/view/trip/trip_timeline_screen.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class TripRoutes {
  static const String trip = '/trip/:id';
  static const String details = '/trip/:id/details';
  static const String timeline = '/trip/:id/timeline';
  static const String chat = '/trip/:id/chat';
  static const String stops = '/trip/:id/stops';
  static const String cancel = '/trip/:id/cancel';

  static String tripOf(String id) => fillPath(trip, {'id': id});

  static String detailsOf(String id) => fillPath(details, {'id': id});

  static String timelineOf(String id) => fillPath(timeline, {'id': id});

  static String chatOf(String id) => fillPath(chat, {'id': id});

  static String stopsOf(String id) => fillPath(stops, {'id': id});

  static String cancelOf(String id) => fillPath(cancel, {'id': id});

  static final List<RouteBase> all = [
    GoRoute(
      path: trip,
      builder: (context, state) => TripScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: details,
      builder: (context, state) => TripDetailsScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: timeline,
      builder: (context, state) => TripTimelineScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: chat,
      builder: (context, state) => TripChatScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: stops,
      builder: (context, state) => AddStopScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: cancel,
      builder: (context, state) => CancelScreen(tripId: state.pathParameters['id']!),
    ),
  ];
}
