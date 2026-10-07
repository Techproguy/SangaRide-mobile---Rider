import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/app_signature.dart';
import 'package:sanga_ride/model/models.dart';

class PlacesService {
  static const String _placesBase = 'https://places.googleapis.com/v1';
  static const String _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

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

  Future<List<PlaceAutocomplete>> getAutocompletePredictions(
    String input, {
    String? sessionToken,
    String? language = 'en',
  }) async {
    input = input.trim();
    if (input.isEmpty) return [];

    try {
      final response = await _dio.post(
        '$_placesBase/places:autocomplete',
        data: {
          'input': input,
          'sessionToken': ?sessionToken,
          'languageCode': ?language,
          'includedRegionCodes': [SangaConstants.placesCountryCode],
        },
        options: _options(),
      );
      if (response.statusCode != 200 || response.data is! Map) return [];

      final suggestions = (response.data['suggestions'] as List?) ?? const [];
      return suggestions
          .whereType<Map>()
          .map((s) => s['placePrediction'])
          .whereType<Map>()
          .map((p) => PlaceAutocomplete.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    } catch (e) {
      log('Error fetching autocomplete predictions: $e');
      return [];
    }
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get('$_placesBase/places/$placeId', options: _options(_placeDetailMask));
      if (response.statusCode != 200 || response.data is! Map) return null;
      return Place.fromJson(Map<String, dynamic>.from(response.data));
    } catch (e) {
      log('Error fetching place details: $e');
      return null;
    }
  }

  Future<List<Place>> searchNearby({
    required double latitude,
    required double longitude,
    int radius = 1500,
    String? type,
    String? keyword,
  }) async {
    if (keyword != null && keyword.isNotEmpty) {
      return _textSearch(keyword, biasLat: latitude, biasLng: longitude, biasRadius: radius);
    }
    try {
      final response = await _dio.post(
        '$_placesBase/places:searchNearby',
        data: {
          if (type != null) 'includedTypes': [type],
          'maxResultCount': 20,
          'locationRestriction': {
            'circle': {
              'center': {'latitude': latitude, 'longitude': longitude},
              'radius': radius.toDouble(),
            },
          },
        },
        options: _options(_placeListMask),
      );
      return _parsePlaces(response);
    } catch (e) {
      log('Error searching nearby places: $e');
      return [];
    }
  }

  Future<List<Place>> searchPlaces(String query) async {
    query = query.trim();
    if (query.isEmpty) return [];
    try {
      return await _textSearch(query);
    } catch (e) {
      log('Error searching places: $e');
      return [];
    }
  }

  Future<List<Place>> _textSearch(String query, {double? biasLat, double? biasLng, int? biasRadius}) async {
    final response = await _dio.post(
      '$_placesBase/places:searchText',
      data: {
        'textQuery': query,
        'regionCode': SangaConstants.placesCountryCode,
        if (biasLat != null && biasLng != null)
          'locationBias': {
            'circle': {
              'center': {'latitude': biasLat, 'longitude': biasLng},
              'radius': (biasRadius ?? 1500).toDouble(),
            },
          },
      },
      options: _options(_placeListMask),
    );
    return _parsePlaces(response);
  }

  List<Place> _parsePlaces(Response response) {
    if (response.statusCode != 200 || response.data is! Map) return [];
    final places = (response.data['places'] as List?) ?? const [];
    return places.whereType<Map>().map((p) => Place.fromJson(Map<String, dynamic>.from(p))).toList();
  }

  Future<GeocodedLocation?> reverseGeocode(LatLng coordinates) async {
    final results = await _geocode(coordinates, resultType: 'street_address|premise|subpremise|route|locality');
    return results.isEmpty ? null : results.first;
  }

  Future<List<GeocodedLocation>> reverseGeocodeAll(LatLng coordinates) => _geocode(coordinates);

  Future<List<GeocodedLocation>> _geocode(LatLng coordinates, {String? resultType}) async {
    try {
      final response = await _dio.get(
        _geocodeUrl,
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
