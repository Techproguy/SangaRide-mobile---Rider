import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show AppEnvironment;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/core/storage_keys.dart';

class SangaConstants {
  SangaConstants._();

  static const String appId = 'com.sangatechnologies.ride';
  static const String appName = 'Sanga Ride';
  static const String userType = 'rider';

  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static const bool roadRoutes = bool.fromEnvironment('ROAD_ROUTES');

  static String get installedAppId => AppEnvironment.current.isProduction ? appId : '$appId.dev';

  static final String googleMapsApiKey = SangaMapsKeys.defaultKey;

  static String get placesCountryCode => SangaRegion.current.placesCountryCode;

  static LatLng get defaultMapCenter => _mapCenters[SangaRegion.current]!;

  static const Map<SangaRegion, LatLng> _mapCenters = {
    SangaRegion.ng: LatLng(6.5244, 3.3792),
    SangaRegion.us: LatLng(29.7604, -95.3698),
  };

  static const SangaFrameConfig frame = SangaFrameConfig();
}
