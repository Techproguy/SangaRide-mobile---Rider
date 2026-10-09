import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_places.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum HomeRefreshProblem { weather, places }

class RiderHomeController extends GetxController {
  static const int _maxRecent = 5;

  final _api = Get.find<ApiService>();
  final _location = LocationService();
  final _places = PlacesService();
  final _saved = Get.find<SavedPlacesController>();
  final _permissions = Get.find<PermissionCenter>();
  final _restore = Get.find<SessionRestore>();
  final _box = GetStorage();

  final Rxn<Place> _currentPlace = Rxn<Place>();
  final Rxn<LocationStatus> _locationStatus = Rxn<LocationStatus>();
  final Rxn<Weather> _weather = Rxn<Weather>();
  final RxList<Place> _recent = <Place>[].obs;
  final RxnString _changedCity = RxnString();
  final RxBool _isLocating = false.obs;
  final RxSet<HomeRefreshProblem> _problems = <HomeRefreshProblem>{}.obs;

  StreamSubscription<void>? _resumeSubscription;
  Worker? _permissionWorker;
  Worker? _tripWorker;
  bool _hadActiveTrip = false;

  bool get isLocating => _isLocating.value;

  Place? get currentPlace => _currentPlace.value;

  Rxn<Place> get currentPlaceObs => _currentPlace;

  LocationStatus? get locationStatus => _locationStatus.value;

  Weather? get weather => _weather.value;

  Place? get home => _saved.home;

  Place? get work => _saved.work;

  List<Place> get recent => _recent;

  String? get changedCity => _changedCity.value;

  bool get hasRefreshProblem => _problems.isNotEmpty;

  PermissionAccess get locationAccess => _permissions.accessOf(PermissionKind.location);

  @override
  void onInit() {
    super.onInit();
    Get.find<RideMatchController>();
    _hadActiveTrip = _restore.meState?.activeTrip != null;
    _resumeSubscription = RefreshMoments.stream.listen((_) => unawaited(refreshHome()));
    _permissionWorker = ever(_permissions.statusRx(PermissionKind.location), _onLocationAccess);
    _tripWorker = ever(_restore.meStateRx, _onMeState);
    unawaited(refreshHome());
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _permissionWorker?.dispose();
    _tripWorker?.dispose();
    super.onClose();
  }

  void _onMeState(MeState? state) {
    final hasActiveTrip = state?.activeTrip != null;
    final returned = _hadActiveTrip && !hasActiveTrip;
    _hadActiveTrip = hasActiveTrip;
    if (returned) unawaited(refreshHome());
  }

  void _onLocationAccess(PermissionAccess access) {
    if (access.isUsable) {
      if (_locationStatus.value != LocationStatus.granted && !isLocating) unawaited(locate());
    } else {
      _locationStatus.value = _statusOf(access);
    }
  }

  LocationStatus _statusOf(PermissionAccess access) => switch (access) {
    PermissionAccess.granted || PermissionAccess.grantedWhileInUse => LocationStatus.granted,
    PermissionAccess.denied => LocationStatus.denied,
    PermissionAccess.permanentlyDenied || PermissionAccess.restricted => LocationStatus.deniedForever,
    PermissionAccess.serviceOff => LocationStatus.serviceDisabled,
  };

  Future<void> refreshHome() async {
    _problems.clear();
    await Future.wait([locate(), _loadWeather(), _loadPlaces(), _saved.load()]);
  }

  Future<PermissionAccess> askForLocation(BuildContext context) async {
    final access = await _permissions.prime(PermissionKind.location, context);
    if (access.isUsable) {
      unawaited(locate());
    } else {
      _locationStatus.value = _statusOf(access);
    }
    return access;
  }

  Future<void> openLocationSettings() => _permissions.openSettings();

  Future<LocationStatus> locate({bool requestPermission = false}) async {
    final access = await _permissions.check(PermissionKind.location);
    if (!access.isUsable && !requestPermission) {
      _locationStatus.value = _statusOf(access);
      return _locationStatus.value!;
    }
    _isLocating.value = true;
    try {
      final result = await _location.resolveCurrentLocation();
      _locationStatus.value = result.status;
      final position = result.position;
      if (position == null) return result.status;
      final place = await _places.placeAt(position);
      if (place == null) return _locationStatus.value = LocationStatus.error;
      _currentPlace.value = place;
      unawaited(_checkCity(place));
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

  Future<String?> _cityOf(Place place) async {
    final coordinates = place.coordinates;
    if (coordinates == null) return null;
    if (!SangaMapsKeys.isConfigured) return MockPlaces.cityAt(coordinates);
    final geocoded = await _places.reverseGeocode(coordinates);
    if (geocoded == null) return null;
    return geocoded.city.isNotEmpty ? geocoded.city : geocoded.state;
  }

  Future<void> _checkCity(Place place) async {
    final city = await _cityOf(place);
    if (city == null || city.isEmpty) return;
    final last = _box.read<String>(SangaStorageKeys.lastCity);
    if (last == null) {
      await _box.write(SangaStorageKeys.lastCity, city);
    } else if (last != city) {
      _changedCity.value = city;
    }
  }

  bool _isSaved(Place place) => _saved.isSaved(place);

  Future<void> rememberPlace(Place place) async {
    if (place.coordinates == null || _isSaved(place)) return;
    _recent
      ..removeWhere((recent) => recent.isSameAs(place))
      ..insert(0, place);
    if (_recent.length > _maxRecent) _recent.removeRange(_maxRecent, _recent.length);
    try {
      await _api.post(AppEndpoints.recentPlaces, data: place.toJson(), suppressErrorToast: true);
    } catch (e) {
      log('remember place failed: $e');
    }
  }

  Future<void> forgetPlace(Place place) async {
    final index = _recent.indexOf(place);
    if (index < 0) return;
    _recent.removeAt(index);
    try {
      await _api.delete(AppEndpoints.recentPlaceOf(place.placeId), suppressErrorToast: true);
    } catch (e) {
      _recent.insert(index.clamp(0, _recent.length), place);
      SangaToast.show('We couldn’t remove that place. Try again.', tone: SangaToastTone.error);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final response = await _api.get(AppEndpoints.weather, suppressErrorToast: true);
      _weather.value = Weather.fromJson((response.data as Map)['data']);
    } catch (e) {
      log('weather failed: $e');
      _problems.add(HomeRefreshProblem.weather);
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final response = await _api.get(AppEndpoints.recentPlaces, suppressErrorToast: true);
      final places = JsonReader.of({'items': (response.data as Map)['data']})
          .listOf('items', (item) => Place.fromJson(item.raw));
      _recent.assignAll(places);
    } catch (e) {
      log('places failed: $e');
      _problems.add(HomeRefreshProblem.places);
    }
  }
}
