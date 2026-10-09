import 'dart:developer';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/services/location_service.dart';

class MapController extends GetxController {
  final LocationService _locationService = LocationService();
  final MapCamera camera = MapCamera();

  final Rx<LatLng?> _currentLocation = Rx<LatLng?>(null);

  LatLng? get currentLocation => _currentLocation.value;

  Rx<LatLng?> get currentLocationObs => _currentLocation;

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) _updateCurrentLocation(location);
    } catch (e) {
      log('Error initializing location: $e');
    }
  }

  void _updateCurrentLocation(LatLng location) => _currentLocation.value = location;

  Future<LocationResult> resolveCurrentLocation({bool mayPrompt = false}) async {
    final result = await _locationService.resolveCurrentLocation(mayPrompt: mayPrompt);
    if (result.isGranted) _updateCurrentLocation(result.position!);
    return result;
  }

  Future<void> openLocationSettings() => _locationService.openLocationSettings();

  Future<void> openAppSettings() => _locationService.openAppSettings();
}
