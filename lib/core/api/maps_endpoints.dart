abstract final class MapsEndpoints {
  static const String _placesBase = 'https://places.googleapis.com/v1';

  static const String routes = 'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const String geocode = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String placesAutocomplete = '$_placesBase/places:autocomplete';
  static const String placesSearchText = '$_placesBase/places:searchText';

  static String placeDetailsOf(String placeId) => '$_placesBase/places/$placeId';
}
