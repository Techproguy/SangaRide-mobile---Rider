import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/maps_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_places.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/app_signature.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride/model/models.dart';

class PlacesService {
  static const String _placeListMask = 'places.id,places.displayName,places.formattedAddress,places.location';
  static const String _placeDetailMask = 'id,displayName,formattedAddress,location';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {if (Platform.isIOS) 'X-Ios-Bundle-Identifier': SangaConstants.iosBundleId},
    ),
  )..interceptors.add(_androidIdentityInterceptor());

  static final String _apiKey = SangaConstants.googleMapsApiKey;

  Options _options([String? fieldMask]) =>
      Options(headers: {'X-Goog-Api-Key': _apiKey, 'X-Goog-FieldMask': ?fieldMask});

  static const double _biasRadiusMeters = 30000;

  Future<List<PlaceAutocomplete>> getAutocompletePredictions(
    String input, {
    String? sessionToken,
    LatLng? origin,
    String language = 'en',
  }) async {
    input = input.trim();
    if (input.isEmpty) return [];
    if (!SangaMapsKeys.isConfigured) return MockPlaces.autocomplete(input, origin: origin);

    final response = await _dio.post(
      MapsEndpoints.placesAutocomplete,
      data: {
        'input': input,
        'sessionToken': ?sessionToken,
        'languageCode': language,
        'includedRegionCodes': [SangaConstants.placesCountryCode],
        if (origin != null) ...{
          'origin': _latLng(origin),
          'locationBias': {
            'circle': {'center': _latLng(origin), 'radius': _biasRadiusMeters},
          },
        },
      },
      options: _options(),
    );
    if (response.data is! Map) return [];
    final suggestions = (response.data['suggestions'] as List?) ?? const [];
    return suggestions
        .whereType<Map>()
        .map((s) => s['placePrediction'])
        .whereType<Map>()
        .map((p) => PlaceAutocomplete.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }

  Future<Place?> getPlaceDetails(String placeId, {String? sessionToken}) async {
    if (!SangaMapsKeys.isConfigured) return MockPlaces.details(placeId);
    final response = await _dio.get(
      MapsEndpoints.placeDetailsOf(placeId),
      queryParameters: {'sessionToken': ?sessionToken},
      options: _options(_placeDetailMask),
    );
    if (response.data is! Map) return null;
    return Place.fromJson(Map<String, dynamic>.from(response.data));
  }

  static Map<String, double> _latLng(LatLng point) => {'latitude': point.latitude, 'longitude': point.longitude};

  Future<List<Place>> searchPlaces(String query) async {
    query = query.trim();
    if (query.isEmpty) return [];
    if (!SangaMapsKeys.isConfigured) return MockPlaces.search(query);
    try {
      return await _textSearch(query);
    } catch (e) {
      log('Error searching places: $e');
      return [];
    }
  }

  Future<List<Place>> _textSearch(String query) async {
    final response = await _dio.post(
      MapsEndpoints.placesSearchText,
      data: {'textQuery': query, 'regionCode': SangaConstants.placesCountryCode},
      options: _options(_placeListMask),
    );
    return _parsePlaces(response);
  }

  List<Place> _parsePlaces(Response response) {
    if (response.statusCode != 200 || response.data is! Map) return [];
    final places = (response.data['places'] as List?) ?? const [];
    return places.whereType<Map>().map((p) => Place.fromJson(Map<String, dynamic>.from(p))).toList();
  }

  Future<Place?> placeAt(LatLng coordinates) async {
    if (!SangaMapsKeys.isConfigured) return MockPlaces.nearest(coordinates);
    final location = await reverseGeocode(coordinates);
    if (location == null) return null;
    final area = location.subLocality ?? location.locality ?? location.route;
    return Place(
      placeId: location.placeId ?? '',
      name: area ?? location.formattedAddress,
      address: location.formattedAddress,
      coordinates: coordinates,
    );
  }

  Future<GeocodedLocation?> reverseGeocode(LatLng coordinates) async {
    final results = await _geocode(coordinates, resultType: 'street_address|premise|subpremise|route|locality');
    return results.isEmpty ? null : results.first;
  }

  Future<List<GeocodedLocation>> _geocode(LatLng coordinates, {String? resultType}) async {
    try {
      final response = await _dio.get(
        MapsEndpoints.geocode,
        queryParameters: {
          'latlng': '${coordinates.latitude},${coordinates.longitude}',
          'key': _apiKey,
          'region': SangaConstants.placesCountryCode,
          'result_type': ?resultType,
        },
      );
      if (response.statusCode != 200 || response.data['status'] != 'OK') return [];
      return (response.data['results'] as List).map((json) => GeocodedLocation.fromJson(json)).toList();
    } catch (e) {
      log('Error reverse geocoding: $e');
      return [];
    }
  }
}

Interceptor _androidIdentityInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (Platform.isAndroid) {
        final sha = await AppSignature.androidCertSha1();
        if (sha != null) {
          options.headers['X-Android-Package'] = SangaConstants.androidPackageName;
          options.headers['X-Android-Cert'] = sha;
        }
      }
      handler.next(options);
    },
  );
}
