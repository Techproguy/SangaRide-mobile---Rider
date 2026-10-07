import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' show PolylinePoints, PointLatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/constants.dart';

class DirectionsService {
  static const String _endpoint = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  final Dio _dio;
  final Map<String, _CachedRoute> _cache = {};

  DirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  static String _key(LatLng origin, LatLng destination) {
    String r(double v) => v.toStringAsFixed(3);
    return '${r(origin.latitude)},${r(origin.longitude)}→${r(destination.latitude)},${r(destination.longitude)}';
  }

  static Map<String, dynamic> _waypoint(LatLng point) => {
    'location': {
      'latLng': {'latitude': point.latitude, 'longitude': point.longitude},
    },
  };

  Future<List<LatLng>?> getRoute(
    LatLng origin,
    LatLng destination, {
    Duration cacheTtl = const Duration(seconds: 60),
  }) async {
    if (origin.latitude == 0 && origin.longitude == 0) return null;
    if (destination.latitude == 0 && destination.longitude == 0) return null;

    final key = _key(origin, destination);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < cacheTtl) return cached.points;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': SangaConstants.googleMapsApiKey,
            'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
          },
        ),
        data: {
          'origin': _waypoint(origin),
          'destination': _waypoint(destination),
          'travelMode': 'DRIVE',
          'polylineEncoding': 'ENCODED_POLYLINE',
          'routingPreference': 'TRAFFIC_AWARE',
        },
      );
      final routes = response.data?['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final encoded = ((routes.first as Map<String, dynamic>)['polyline'] as Map<String, dynamic>?)?['encodedPolyline'];
      if (encoded is! String || encoded.isEmpty) return null;

      final decoded = PolylinePoints.decodePolyline(encoded)
          .map((PointLatLng p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);
      if (decoded.length < 2) return null;
      _cache[key] = _CachedRoute(decoded, DateTime.now());
      return decoded;
    } on DioException catch (e) {
      log('DirectionsService DioException: ${e.response?.statusCode} ${e.message} body=${e.response?.data}');
      return null;
    } catch (e) {
      log('DirectionsService error: $e');
      return null;
    }
  }

  void clear() => _cache.clear();
}

class _CachedRoute {
  final List<LatLng> points;
  final DateTime fetchedAt;

  _CachedRoute(this.points, this.fetchedAt);
}
