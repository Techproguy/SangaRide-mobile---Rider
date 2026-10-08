import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride/model/models.dart';

class RiderHomeController extends GetxController {
  final _api = Get.find<ApiService>();
  final _location = LocationService();
  final _places = PlacesService();
  final _saved = Get.find<SavedPlacesController>();
  final _box = GetStorage();

  final Rxn<Place> _currentPlace = Rxn<Place>();
  final Rxn<LocationStatus> _locationStatus = Rxn<LocationStatus>();
  final Rxn<Weather> _weather = Rxn<Weather>();
  final RxList<Place> _recent = <Place>[].obs;
  final RxnString _changedCity = RxnString();
  final RxBool _isLocating = false.obs;

  bool get isLocating => _isLocating.value;

  Place? get currentPlace => _currentPlace.value;

  Rxn<Place> get currentPlaceObs => _currentPlace;

  LocationStatus? get locationStatus => _locationStatus.value;

  Weather? get weather => _weather.value;

  Place? get home => _saved.home;

  Place? get work => _saved.work;

  List<Place> get recent => _recent;

  String? get changedCity => _changedCity.value;

  @override
  void onInit() {
    super.onInit();
    refreshHome();
  }

  Future<void> refreshHome() => Future.wait([locate(), _loadWeather(), _loadPlaces(), _saved.load()]);

  Future<LocationStatus> locate() async {
    _isLocating.value = true;
    try {
      final result = await _location.resolveCurrentLocation();
      _locationStatus.value = result.status;
      final position = result.position;
      if (position == null) return result.status;
      final place = await _places.placeAt(position);
      if (place == null) return LocationStatus.error;
      _currentPlace.value = place;
      _checkCity(place);
      return result.status;
    } finally {
      _isLocating.value = false;
    }
  }

  void confirmCity() {
    final city = _changedCity.value;
    if (city != null) _box.write(SangaStorageKeys.lastCity, city);
    _changedCity.value = null;
  }

  void dismissCity() => _changedCity.value = null;

  void _checkCity(Place place) {
    final city = place.address.split(',').last.trim();
    if (city.isEmpty) return;
    final last = _box.read<String>(SangaStorageKeys.lastCity);
    if (last == null) {
      _box.write(SangaStorageKeys.lastCity, city);
    } else if (last != city) {
      _changedCity.value = city;
    }
  }

  static const int _maxRecent = 5;

  bool _isSaved(Place place) => _saved.isSaved(place);

  Future<void> rememberPlace(Place place) async {
    if (place.coordinates == null || _isSaved(place)) return;
    _recent
      ..removeWhere((recent) => recent.isSameAs(place))
      ..insert(0, place);
    if (_recent.length > _maxRecent) _recent.removeRange(_maxRecent, _recent.length);
    try {
      await _api.post(MockEndpoints.recentPlaces, data: place.toJson(), suppressErrorToast: true);
    } catch (e) {
      log('remember place failed: $e');
    }
  }

  Future<void> forgetPlace(Place place) async {
    final index = _recent.indexOf(place);
    if (index < 0) return;
    _recent.removeAt(index);
    try {
      await _api.delete(
        MockEndpoints.recentPlaceOf(place.placeId),
        options: Options(extra: {'suppressErrorToast': true}),
      );
    } catch (e) {
      _recent.insert(index.clamp(0, _recent.length), place);
      Toast.error('We couldn’t remove that place. Try again.');
    }
  }

  Future<void> _loadWeather() async {
    try {
      final response = await _api.get(MockEndpoints.weather);
      _weather.value = Weather.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
    } catch (e) {
      log('weather failed: $e');
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final response = await _api.get(MockEndpoints.recentPlaces);
      _recent.assignAll((response.data['data'] as List).map(_place).whereType<Place>());
    } catch (e) {
      log('places failed: $e');
    }
  }

  Place? _place(Object? json) => json is Map ? Place.fromJson(Map<String, dynamic>.from(json)) : null;
}
