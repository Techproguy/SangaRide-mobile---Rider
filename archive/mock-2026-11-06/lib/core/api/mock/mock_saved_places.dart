import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class MockSavedPlaces {
  static final List<MockRoute> routes = [
    MockRoute.get(PlacesEndpoints.saved, (_) => _payload()),
    MockRoute.post(PlacesEndpoints.saved, _create),
    MockRoute.patch(PlacesEndpoints.savedById, _update),
    MockRoute.delete(PlacesEndpoints.savedById, _delete),
  ];

  static const int _maxOthers = 10;
  static const int _maxLabelLength = 24;

  static const String _storageKey = 'mock_saved_places';

  static final GetStorage _box = GetStorage();
  static final Map<SangaRegion, List<Map<String, dynamic>>> _placesByRegion = {};

  static String get _regionKey => MockRegion.isUnitedStates ? '${_storageKey}_us' : _storageKey;

  static List<Map<String, dynamic>> get _places =>
      _placesByRegion.putIfAbsent(MockRegion.current, () => _stored() ?? _seed());

  static List<Map<String, dynamic>> _seed() => [
    {'id': 'sp_home', 'kind': 'home', 'label': 'Home', 'place': MockRegion.place('mock_home')},
    {'id': 'sp_work', 'kind': 'work', 'label': 'Work', 'place': MockRegion.place('mock_work')},
  ];

  static List<Map<String, dynamic>>? _stored() {
    final raw = _box.read<List<dynamic>>(_regionKey);
    if (raw == null) return null;
    return [
      for (final entry in raw)
        if (entry is Map) Map<String, dynamic>.from(entry),
    ];
  }

  static void _keep() => _box.write(_regionKey, _places);


  static List<Map<String, dynamic>> _payload() => [for (final place in _places) _out(place)];

  static List<Map<String, dynamic>> get _others => [
    for (final place in _places)
      if (place['kind'] == 'other') place,
  ];

  static Map<String, dynamic> _validPlace(Object? value) {
    final place = value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
    final coordinates = place['coordinates'];
    final hasCoordinates = coordinates is Map && coordinates['lat'] is num && coordinates['lng'] is num;
    final hasName = (place['name'] as String? ?? '').trim().isNotEmpty;
    if (!hasCoordinates || !hasName) {
      throw const MockFailure(422, 'We couldn’t use that location.', code: 'invalid_place');
    }
    return place;
  }

  static String _validLabel(Object? value, {String? exceptId}) {
    final label = (value as String? ?? '').trim();
    if (label.isEmpty || label.length > _maxLabelLength) {
      throw const MockFailure(422, 'Give this place a short name.', code: 'invalid_label');
    }
    final lower = label.toLowerCase();
    final isReserved = lower == 'home' || lower == 'work';
    final isTaken = _others.any(
      (place) => place['id'] != exceptId && (place['label'] as String).toLowerCase() == lower,
    );
    if (isReserved || isTaken) {
      throw const MockFailure(409, 'You already have a place with that name.', code: 'duplicate_label');
    }
    return label;
  }

  static Map<String, dynamic> _out(Map<String, dynamic> saved) {
    final place = Map<String, dynamic>.from(saved['place'] as Map);
    final coordinates = place['coordinates'] as Map?;
    return {
      'id': saved['id'],
      'label': saved['kind'] == 'other' ? 'custom' : saved['kind'],
      'name': saved['label'],
      'address': place['address'] ?? '',
      if ('${place['place_id'] ?? ''}'.isNotEmpty) 'placeId': place['place_id'],
      'latitude': coordinates?['lat'],
      'longitude': coordinates?['lng'],
    };
  }

  static String? _kindOf(Object? apiLabel) => switch (apiLabel) {
    'home' => 'home',
    'work' => 'work',
    'custom' => 'other',
    _ => null,
  };

  static Map<String, dynamic> _placeOf(Map<String, dynamic> body) => {
    'place_id': body['placeId'] ?? '',
    'name': body['name'],
    'address': body['address'] ?? '',
    'coordinates': {'lat': body['latitude'], 'lng': body['longitude']},
  };

  static Object? _create(MockRequest request) {
    final kind = _kindOf(request.body['label']);
    if (kind == null) {
      throw const MockFailure(422, 'Pick what kind of place this is.', code: 'invalid_kind');
    }
    final place = _validPlace(_placeOf(request.body));
    if (kind != 'other') return _setSlot(kind, place);
    final label = _validLabel(request.body['name']);
    if (_others.length >= _maxOthers) {
      throw const MockFailure(
        409,
        'You’ve saved as many places as you can.',
        code: 'limit_reached',
        data: {'max': _maxOthers},
      );
    }
    final saved = {
      'id': 'sp_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'other',
      'label': label,
      'place': place,
    };
    _places.add(saved);
    _keep();
    return _out(saved);
  }

  static Map<String, dynamic> _setSlot(String kind, Map<String, dynamic> place) {
    if (kind == 'home') MockAccount.completeOnboardingStep(MockOnboardingStep.home);
    final existing = _places.where((saved) => saved['kind'] == kind).firstOrNull;
    if (existing != null) {
      existing['place'] = place;
      _keep();
      return _out(existing);
    }
    final saved = {'id': 'sp_$kind', 'kind': kind, 'label': kind == 'home' ? 'Home' : 'Work', 'place': place};
    _places.add(saved);
    _keep();
    return _out(saved);
  }

  static Map<String, dynamic> _require(MockRequest request) {
    final saved = _places.where((place) => place['id'] == request.params['id']).firstOrNull;
    if (saved == null) throw const MockFailure(404, 'We can’t find that place.', code: 'not_found');
    return saved;
  }

  static Object? _update(MockRequest request) {
    final saved = _require(request);
    final isSlot = saved['kind'] != 'other';
    final label = isSlot || !request.body.containsKey('name')
        ? saved['label']
        : _validLabel(request.body['name'], exceptId: saved['id'] as String);
    final place = request.body.containsKey('latitude') ? _validPlace(_placeOf(request.body)) : saved['place'];
    saved
      ..['label'] = label
      ..['place'] = place;
    _keep();
    return _out(saved);
  }

  static Object? _delete(MockRequest request) {
    final saved = _require(request);
    _places.remove(saved);
    _keep();
    return {'id': saved['id'], 'deleted': true};
  }
}
