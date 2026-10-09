import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' show PolylinePoints, PointLatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/maps_endpoints.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/storage_keys.dart';

class DirectionsService {
  final Dio _dio;
  final Map<String, _CachedRoute> _cache = {};

  DirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  static String _key(List<LatLng> points) {
    String r(double v) => v.toStringAsFixed(3);
    return points.map((p) => '${r(p.latitude)},${r(p.longitude)}').join('|');
  }

  static Map<String, dynamic> _waypoint(LatLng point) => {
    'location': {
      'latLng': {'latitude': point.latitude, 'longitude': point.longitude},
    },
  };

  Future<List<LatLng>?> getRoute(List<LatLng> points, {Duration cacheTtl = const Duration(seconds: 60)}) async {
    if (points.length < 2 || !SangaMapsKeys.isConfigured) return null;
    if (points.any((p) => p.latitude == 0 && p.longitude == 0)) return null;

    final key = _key(points);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < cacheTtl) return cached.points;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        MapsEndpoints.routes,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': SangaConstants.googleMapsApiKey,
            'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
          },
        ),
        data: {
          'origin': _waypoint(points.first),
          'destination': _waypoint(points.last),
          if (points.length > 2)
            'intermediates': [for (final stop in points.sublist(1, points.length - 1)) _waypoint(stop)],
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
