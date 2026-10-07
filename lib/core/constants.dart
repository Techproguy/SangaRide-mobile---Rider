import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/core/storage_keys.dart';

class SangaConstants {
  SangaConstants._();

  static const String appName = 'Sanga Ride';

  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static const String iosBundleId = 'com.sangatechnologies.ride';
  static const String androidPackageName = 'com.sangatechnologies.ride';

  static final String googleMapsApiKey = SangaMapsKeys.defaultKey;

  static const String placesCountryCode = 'ng';

  static const LatLng defaultMapCenter = LatLng(6.5244, 3.3792);

  static const SangaFrameConfig frame = SangaFrameConfig();
}
