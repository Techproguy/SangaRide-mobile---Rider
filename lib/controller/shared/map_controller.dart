import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/map/sanga_marker_icons.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MapController extends GetxController {
  static const String pickupMarkerId = 'pickup';
  static const String dropoffMarkerId = 'dropoff';
  static const String driverMarkerId = 'driver';

  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  final MapCamera camera = MapCamera();

  final Rx<LatLng?> _currentLocation = Rx<LatLng?>(null);
  final RxBool _isLoadingLocation = false.obs;
  final RxSet<Marker> _markers = <Marker>{}.obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;

  StreamSubscription<LatLng>? _locationSubscription;

  LatLng? get currentLocation => _currentLocation.value;

  Rx<LatLng?> get currentLocationObs => _currentLocation;

  bool get isLoadingLocation => _isLoadingLocation.value;

  Set<Marker> get markers => _markers;

  Set<Polyline> get polylines => _polylines;

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    _isLoadingLocation.value = true;
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) _updateCurrentLocation(location);
    } catch (e) {
      log('Error initializing location: $e');
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  void _updateCurrentLocation(LatLng location) => _currentLocation.value = location;

  void startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen(_updateCurrentLocation);
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _placeMarker({
    required String id,
    required LatLng position,
    required BitmapDescriptor icon,
    Offset anchor = const Offset(0.5, 1.0),
    String? title,
    String? snippet,
    double rotation = 0,
    int zIndex = 0,
  }) async {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title, snippet: snippet),
        icon: icon,
        anchor: anchor,
        rotation: rotation,
        zIndexInt: zIndex,
      ),
    );
  }

  Future<void> setPickupMarker(LatLng position, {String? title}) async {
    await _placeMarker(id: pickupMarkerId, position: position, icon: await SangaMarkerIcons.pickup(), title: title);
  }

  Future<void> setDropoffMarker(LatLng position, {String? title}) async {
    await _placeMarker(id: dropoffMarkerId, position: position, icon: await SangaMarkerIcons.dropoff(), title: title);
  }

  Future<void> setDriverMarker(LatLng position, {String? title}) async {
    await _placeMarker(
      id: driverMarkerId,
      position: position,
      icon: await SangaMarkerIcons.driver(),
      title: title,
      zIndex: 50,
    );
  }

  void setPolyline({
    required String id,
    required List<LatLng> points,
    Color color = SangaColors.primary,
    int width = 4,
  }) {
    _polylines.removeWhere((p) => p.polylineId.value == id);
    if (points.length < 2) return;
    _polylines.add(
      Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: color,
        width: width,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );
  }

  void removePolyline(String id) => _polylines.removeWhere((p) => p.polylineId.value == id);

  void clearPolylines() => _polylines.clear();

  void removeMarker(String id) => _markers.removeWhere((m) => m.markerId.value == id);

  void clearMarkers() => _markers.clear();

  Future<GeocodedLocation?> reverseGeocode(LatLng position) => _placesService.reverseGeocode(position);

  Future<List<Place>> searchNearby({String? type, String? keyword, int radius = 1500}) async {
    final current = _currentLocation.value;
    if (current == null) return [];
    return _placesService.searchNearby(
      latitude: current.latitude,
      longitude: current.longitude,
      radius: radius,
      type: type,
      keyword: keyword,
    );
  }

  double? getDistanceFromCurrent(LatLng destination) {
    final current = _currentLocation.value;
    return current == null ? null : _locationService.calculateDistance(current, destination);
  }

  Future<LocationResult> resolveCurrentLocation() async {
    final result = await _locationService.resolveCurrentLocation();
    if (result.isGranted) _updateCurrentLocation(result.position!);
    return result;
  }

  Future<void> openLocationSettings() => _locationService.openLocationSettings();

  Future<void> openAppSettings() => _locationService.openAppSettings();
}
