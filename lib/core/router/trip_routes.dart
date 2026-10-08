import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/trip/trip_chat_screen.dart';
import 'package:sanga_ride/view/trip/trip_details_screen.dart';
import 'package:sanga_ride/view/trip/trip_screen.dart';
import 'package:sanga_ride/view/trip/trip_timeline_screen.dart';

abstract final class TripRoutes {
  static const String trip = '/trip/:id';
  static const String details = '/trip/:id/details';
  static const String timeline = '/trip/:id/timeline';
  static const String chat = '/trip/:id/chat';

  static String tripOf(String id) => trip.replaceFirst(':id', id);

  static String detailsOf(String id) => details.replaceFirst(':id', id);

  static String timelineOf(String id) => timeline.replaceFirst(':id', id);

  static String chatOf(String id) => chat.replaceFirst(':id', id);

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
  ];
}
