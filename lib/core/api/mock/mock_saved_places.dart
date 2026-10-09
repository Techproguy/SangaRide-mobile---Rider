import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';

abstract final class MockSavedPlaces {
  static final List<MockRoute> routes = [
    MockRoute.get(PlacesEndpoints.saved, (_) => _payload()),
    MockRoute.post(PlacesEndpoints.saved, _create),
    MockRoute.patch(PlacesEndpoints.savedById, _update),
    MockRoute.delete(PlacesEndpoints.savedById, _delete),
  ];

  static const int _maxOthers = 10;
  static const int _maxLabelLength = 24;

  static final List<Map<String, dynamic>> _places = [
    {
      'id': 'sp_home',
      'kind': 'home',
      'label': 'Home',
      'place': {
        'place_id': 'mock_home',
        'name': '12 Ajegule Street',
        'address': '12 Ajegule Street, Ikorodu, Lagos',
        'coordinates': {'lat': 6.6194, 'lng': 3.5105},
      },
    },
    {
      'id': 'sp_work',
      'kind': 'work',
      'label': 'Work',
      'place': {
        'place_id': 'mock_work',
        'name': 'Akeredolu Building',
        'address': 'Akeredolu Building, Agege, Lagos',
        'coordinates': {'lat': 6.6180, 'lng': 3.3209},
      },
    },
  ];

  static int _created = 0;

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static Map<String, dynamic> _payload() => {
    'places': [for (final place in _places) Map<String, dynamic>.of(place)],
    'maxOthers': _maxOthers,
    'serverTime': _iso(DateTime.now()),
  };

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

  static Object? _create(MockRequest request) {
    final kind = request.body['kind'] as String?;
    if (kind != 'home' && kind != 'work' && kind != 'other') {
      throw const MockFailure(422, 'Pick what kind of place this is.', code: 'invalid_kind');
    }
    final place = _validPlace(request.body['place']);
    if (kind != 'other') return _setSlot(kind!, place);
    final label = _validLabel(request.body['label']);
    if (_others.length >= _maxOthers) {
      throw const MockFailure(
        409,
        'You’ve saved as many places as you can.',
        code: 'limit_reached',
        data: {'max': _maxOthers},
      );
    }
    final saved = {'id': 'sp_${++_created}', 'kind': 'other', 'label': label, 'place': place};
    _places.add(saved);
    return Map<String, dynamic>.of(saved);
  }

  static Map<String, dynamic> _setSlot(String kind, Map<String, dynamic> place) {
    final existing = _places.where((saved) => saved['kind'] == kind).firstOrNull;
    if (existing != null) {
      existing['place'] = place;
      return Map<String, dynamic>.of(existing);
    }
    final saved = {'id': 'sp_$kind', 'kind': kind, 'label': kind == 'home' ? 'Home' : 'Work', 'place': place};
    _places.add(saved);
    if (kind == 'home') MockAccount.completeOnboardingStep(MockOnboardingStep.home);
    return Map<String, dynamic>.of(saved);
  }

  static Map<String, dynamic> _require(MockRequest request) {
    final saved = _places.where((place) => place['id'] == request.params['id']).firstOrNull;
    if (saved == null) throw const MockFailure(404, 'We can’t find that place.', code: 'not_found');
    return saved;
  }

  static Object? _update(MockRequest request) {
    final saved = _require(request);
    final isSlot = saved['kind'] != 'other';
    final label = isSlot || !request.body.containsKey('label')
        ? saved['label']
        : _validLabel(request.body['label'], exceptId: saved['id'] as String);
    final place = request.body.containsKey('place') ? _validPlace(request.body['place']) : saved['place'];
    saved
      ..['label'] = label
      ..['place'] = place;
    return Map<String, dynamic>.of(saved);
  }

  static Object? _delete(MockRequest request) {
    final saved = _require(request);
    _places.remove(saved);
    return {'id': saved['id'], 'deleted': true};
  }
}
