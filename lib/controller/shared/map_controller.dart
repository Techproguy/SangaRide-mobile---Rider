import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/colors.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/map/sanga_marker_icons.dart';

class MapController extends GetxController {
  static const String selfMarkerId = 'current_location';
  static const String pickupMarkerId = 'pickup';
  static const String dropoffMarkerId = 'dropoff';
  static const String driverMarkerId = 'driver';
  static const String selectedPlaceMarkerId = 'selected_place';

  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();

  final Rx<LatLng?> _currentLocation = Rx<LatLng?>(null);
  final RxBool _isLoadingLocation = false.obs;
  final RxBool _isSearching = false.obs;
  final RxList<PlaceAutocomplete> _searchResults = <PlaceAutocomplete>[].obs;
  final RxSet<Marker> _markers = <Marker>{}.obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;
  final Rx<Place?> _selectedPlace = Rx<Place?>(null);
  final RxString _searchQuery = ''.obs;

  bool _selectionInProgress = false;

  GoogleMapController? _mapController;
  bool _attached = false;
  StreamSubscription<LatLng>? _locationSubscription;

  final Rx<EdgeInsets> visibleInsets = EdgeInsets.zero.obs;
  Size mapSize = Size.zero;

  String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  LatLng? get currentLocation => _currentLocation.value;

  Rx<LatLng?> get currentLocationObs => _currentLocation;

  bool get isLoadingLocation => _isLoadingLocation.value;

  bool get isSearching => _isSearching.value;

  List<PlaceAutocomplete> get searchResults => _searchResults;

  Set<Marker> get markers => _markers;

  Set<Polyline> get polylines => _polylines;

  Place? get selectedPlace => _selectedPlace.value;

  String get searchQuery => _searchQuery.value;

  bool get isMapAttached => _attached && _mapController != null;

  set searchQuery(String query) {
    _selectionInProgress = false;
    _searchQuery.value = query;
    if (query.trim().isEmpty) {
      _isSearching.value = false;
      _searchResults.clear();
    } else {
      _isSearching.value = true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
    debounce(_searchQuery, _performSearch, time: const Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    clearMapController();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    _isLoadingLocation.value = true;
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) await _updateCurrentLocation(location);
    } catch (e) {
      log('Error initializing location: $e');
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<void> _updateCurrentLocation(LatLng location) async {
    _currentLocation.value = location;
    await _placeMarker(
      id: selfMarkerId,
      position: location,
      icon: await SangaMarkerIcons.self(),
      anchor: const Offset(0.5, 0.5),
      zIndex: 100,
    );
  }

  void startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen(_updateCurrentLocation);
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    _attached = true;
  }

  void clearMapController() {
    _attached = false;
    _mapController = null;
  }

  void setVisibleInsets(EdgeInsets insets) => visibleInsets.value = insets;

  void updateVisibleInsets({double? top, double? bottom, double? left, double? right}) {
    final c = visibleInsets.value;
    visibleInsets.value = EdgeInsets.only(
      top: top ?? c.top,
      bottom: bottom ?? c.bottom,
      left: left ?? c.left,
      right: right ?? c.right,
    );
  }

  LatLng _biasToVisible(LatLng target, LatLngBounds region) {
    final h = mapSize.height, w = mapSize.width;
    if (h <= 0 || w <= 0) return target;
    final ins = visibleInsets.value;
    final latSpan = region.northeast.latitude - region.southwest.latitude;
    final lngSpan = region.northeast.longitude - region.southwest.longitude;
    final latShift = ((ins.top - ins.bottom) / (2 * h)) * latSpan;
    final lngShift = ((ins.right - ins.left) / (2 * w)) * lngSpan;
    return LatLng(target.latitude + latShift, target.longitude + lngShift);
  }

  Future<void> moveCamera(LatLng position, {double zoom = 14.0}) async {
    final ctrl = _mapController;
    if (!_attached || ctrl == null) return;
    try {
      final region = await ctrl.getVisibleRegion();
      await ctrl.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: _biasToVisible(position, region), zoom: zoom)),
      );
    } on StateError {
      return;
    }
  }

  Future<void> fitBounds(
    List<LatLng> points, {
    double padding = 80,
    double singlePointZoom = 14,
    double maxZoom = 16.5,
  }) async {
    final ctrl = _mapController;
    if (!_attached || ctrl == null || points.isEmpty) return;
    if (points.length == 1) return moveCamera(points.first, zoom: singlePointZoom);
    try {
      var minLat = points.first.latitude, maxLat = minLat;
      var minLng = points.first.longitude, maxLng = minLng;
      for (final p in points.skip(1)) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final ins = visibleInsets.value;
      final visH = mapSize.height - ins.top - ins.bottom;
      final visW = mapSize.width - ins.left - ins.right;
      if (visH > 0 && (ins.top > 0 || ins.bottom > 0)) {
        final latSpan = (maxLat - minLat).abs();
        maxLat += latSpan * (ins.top / visH);
        minLat -= latSpan * (ins.bottom / visH);
      }
      if (visW > 0 && (ins.left > 0 || ins.right > 0)) {
        final lngSpan = (maxLng - minLng).abs();
        minLng -= lngSpan * (ins.left / visW);
        maxLng += lngSpan * (ins.right / visW);
      }

      final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
      await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
      if (await ctrl.getZoomLevel() > maxZoom) {
        await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2), maxZoom),
        );
      }
    } on StateError {
      return;
    }
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
    Color color = SangaColors.accent,
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

  void clearMarkers({bool keepCurrentLocation = true}) {
    if (keepCurrentLocation) {
      _markers.removeWhere((m) => m.markerId.value != selfMarkerId);
    } else {
      _markers.clear();
    }
  }

  Future<void> _performSearch(String query) async {
    if (_selectionInProgress || query.trim().isEmpty) {
      _isSearching.value = false;
      if (query.trim().isEmpty) _searchResults.clear();
      return;
    }

    _isSearching.value = true;
    try {
      _searchResults.value = await _placesService.getAutocompletePredictions(query, sessionToken: _sessionToken);
    } catch (e) {
      log('Error performing search: $e');
      _searchResults.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  Future<Place?> selectPlace(PlaceAutocomplete prediction) async {
    try {
      final place = await _placesService.getPlaceDetails(prediction.placeId);
      final coordinates = place?.coordinates;
      if (place == null || coordinates == null) return null;

      _selectionInProgress = true;
      _selectedPlace.value = place;
      _searchResults.clear();
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

      await _placeMarker(
        id: selectedPlaceMarkerId,
        position: coordinates,
        icon: await SangaMarkerIcons.dropoff(),
        title: place.name,
        snippet: place.address,
      );
      await moveCamera(coordinates);
      return place;
    } catch (e) {
      log('Error selecting place: $e');
      return null;
    }
  }

  void clearSearch() {
    _selectionInProgress = false;
    _searchQuery.value = '';
    _searchResults.clear();
    _selectedPlace.value = null;
    removeMarker(selectedPlaceMarkerId);
  }

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
    if (result.isGranted) await _updateCurrentLocation(result.position!);
    return result;
  }

  Future<void> openLocationSettings() => _locationService.openLocationSettings();

  Future<void> openAppSettings() => _locationService.openAppSettings();
}
