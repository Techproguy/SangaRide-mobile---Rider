abstract final class PlacesEndpoints {
  static const String saved = '/places/saved';
  static const String savedById = '/places/saved/:id';

  static String savedOf(String id) => savedById.replaceFirst(':id', id);
}
