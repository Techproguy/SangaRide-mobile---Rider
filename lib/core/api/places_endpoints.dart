import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class PlacesEndpoints {
  static const String saved = '/places/saved';
  static const String savedById = '/places/saved/:id';

  static String savedOf(String id) => fillPath(savedById, {'id': id});
}
