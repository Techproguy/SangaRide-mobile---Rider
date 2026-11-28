import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/core/storage_keys.dart';

class SangaConstants {
  SangaConstants._();

  static const String appId = 'com.sangatechnologies.ride';
  static const String appName = 'Sanga Ride';
  static const String userType = 'rider';
  static const String googleServerClientId = '889203916709-9raiunpo9og0deo7p3r18a6ghhm812se.apps.googleusercontent.com';

  static const String baseUrl = 'https://api-staging.sangaride.com';

  static const String googleMapsApiKey = SangaMapsKeys.key;

  static String get placesCountryCode => SangaRegion.current.placesCountryCode;

  // TODO(#270): read the map centre when GET /config sends defaultMapCenter
  static LatLng get defaultMapCenter => _mapCenters[SangaRegion.current]!;

  static const Map<SangaRegion, LatLng> _mapCenters = {
    SangaRegion.ng: LatLng(6.5244, 3.3792),
    SangaRegion.us: LatLng(29.7604, -95.3698),
  };

  static const SangaFrameConfig frame = SangaFrameConfig();
}
