import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationStatus { granted, serviceDisabled, denied, deniedForever, error }

class LocationResult {
  final LocationStatus status;
  final LatLng? position;

  const LocationResult(this.status, [this.position]);

  bool get isGranted => status == LocationStatus.granted && position != null;
}

class LocationService {
  static const _recentFixAge = Duration(minutes: 2);
  static const _attemptLimit = Duration(seconds: 12);
  static const _fixAttempts = [
    LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
    LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
  ];

  static Future<LocationResult>? _inFlight;

  Future<LocationResult> resolveCurrentLocation({bool mayPrompt = false}) =>
      _inFlight ??= _resolve(mayPrompt: mayPrompt).whenComplete(() => _inFlight = null);

  Future<LocationResult> _resolve({required bool mayPrompt}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && mayPrompt) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return const LocationResult(LocationStatus.denied);
      if (permission == LocationPermission.deniedForever) return const LocationResult(LocationStatus.deniedForever);

      final position = await _bestFix();
      if (position == null) return const LocationResult(LocationStatus.error);
      return LocationResult(LocationStatus.granted, LatLng(position.latitude, position.longitude));
    } catch (e) {
      log('resolveCurrentLocation error: $e');
      return const LocationResult(LocationStatus.error);
    }
  }

  static Future<Position?> _bestFix() async {
    final lastKnown = await _lastKnown();
    if (lastKnown != null && DateTime.now().difference(lastKnown.timestamp) < _recentFixAge) return lastKnown;
    for (final settings in _fixAttempts) {
      try {
        return await Geolocator.getCurrentPosition(locationSettings: settings).timeout(_attemptLimit);
      } catch (e) {
        log('location fix at ${settings.accuracy.name} failed: ${e.runtimeType}');
      }
    }
    return lastKnown;
  }

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> getCurrentLocation() async => (await resolveCurrentLocation()).position;

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
