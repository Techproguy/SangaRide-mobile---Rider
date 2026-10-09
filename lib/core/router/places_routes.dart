import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/places/saved_place_edit_screen.dart';
import 'package:sanga_ride/view/places/saved_places_screen.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class PlacesRoutes {
  static const String saved = '/places';
  static const String edit = '/places/edit/:kind';

  static const String _idKey = 'id';

  static String editOf(SavedPlaceKind kind, {String? id}) {
    final path = fillPath(edit, {'kind': kind.code});
    return id == null ? path : Uri(path: path, queryParameters: {_idKey: id}).toString();
  }

  static final List<RouteBase> all = [
    GoRoute(path: saved, builder: (context, state) => const SavedPlacesScreen()),
    GoRoute(
      path: edit,
      builder: (context, state) => SavedPlaceEditScreen(
        kind: SavedPlaceKind.values.asNameMap()[state.pathParameters['kind']] ?? SavedPlaceKind.other,
        placeId: state.uri.queryParameters[_idKey],
      ),
    ),
  ];
}
