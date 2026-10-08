import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/safety/emergency_contacts_screen.dart';
import 'package:sanga_ride/view/safety/safety_centre_screen.dart';
import 'package:sanga_ride/view/safety/safety_report_screen.dart';

abstract final class SafetyRoutes {
  static const String centre = '/safety';
  static const String contacts = '/safety/contacts';
  static const String report = '/safety/report';

  static const String _tripIdKey = 'tripId';

  static String centreOf({String? tripId}) => _withTrip(centre, tripId);

  static String reportOf({String? tripId}) => _withTrip(report, tripId);

  static String _withTrip(String path, String? tripId) =>
      tripId == null ? path : Uri(path: path, queryParameters: {_tripIdKey: tripId}).toString();

  static final List<RouteBase> all = [
    GoRoute(
      path: centre,
      builder: (context, state) => SafetyCentreScreen(tripId: state.uri.queryParameters[_tripIdKey]),
    ),
    GoRoute(path: contacts, builder: (context, state) => const EmergencyContactsScreen()),
    GoRoute(
      path: report,
      builder: (context, state) => SafetyReportScreen(tripId: state.uri.queryParameters[_tripIdKey]),
    ),
  ];
}
