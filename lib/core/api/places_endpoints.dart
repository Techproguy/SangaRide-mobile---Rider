import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class PlacesEndpoints {
  static const String saved = '/places';
  static const String savedById = '/places/:id';

  static String savedOf(String id) => fillPath(savedById, {'id': id});
}
