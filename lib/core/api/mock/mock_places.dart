import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/model/models.dart';

class MockPlaces {
  MockPlaces._();

  static const Duration _latency = Duration(milliseconds: 300);
  static const int _maxResults = 6;

  static String? cityAt(LatLng point) {
    String? nearest;
    var nearestMeters = double.infinity;
    for (final city in (MockBooking.cities['cities'] as List).cast<Map<String, dynamic>>()) {
      final meters = LatLng(city['lat'] as double, city['lng'] as double).metersTo(point);
      if (meters <= (city['radiusKm'] as num) * 1000 && meters < nearestMeters) {
        nearest = city['name'] as String;
        nearestMeters = meters;
      }
    }
    return nearest;
  }

  static List<Place> get _all => [for (final spec in MockRegion.searchable) spec.model];

  static List<Place> _matching(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    return _all.where((place) => '${place.name} ${place.address}'.toLowerCase().contains(needle)).toList();
  }

  static Future<List<Place>> search(String query) async {
    await Future<void>.delayed(_latency);
    return _matching(query);
  }

  static Future<List<PlaceAutocomplete>> autocomplete(String query, {LatLng? origin}) async {
    await Future<void>.delayed(_latency);
    final matches = _matching(query);
    int? distanceTo(Place place) => origin == null ? null : place.coordinates!.metersTo(origin).round();
    if (origin != null) matches.sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    return [
      for (final place in matches.take(_maxResults))
        PlaceAutocomplete(
          placeId: place.placeId,
          description: '${place.name}, ${place.address}',
          mainText: place.name,
          secondaryText: place.address,
          distanceMeters: distanceTo(place),
        ),
    ];
  }

  static Future<Place?> details(String placeId) async {
    await Future<void>.delayed(_latency);
    for (final place in _all) {
      if (place.placeId == placeId) return place;
    }
    return null;
  }

  static Future<Place> nearest(LatLng position) async {
    await Future<void>.delayed(_latency);
    final area = [for (final spec in MockRegion.areas) spec.model]
        .reduce((a, b) => a.coordinates!.metersTo(position) <= b.coordinates!.metersTo(position) ? a : b);
    return Place(placeId: 'mock_current', name: area.name, address: area.address, coordinates: position);
  }
}
