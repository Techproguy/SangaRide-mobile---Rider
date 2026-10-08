import 'package:go_router/go_router.dart';

abstract final class TripRoutes {
  static const String trip = '/trip/:id';

  static String tripOf(String id) => trip.replaceFirst(':id', id);

  static final List<RouteBase> all = [];
}
