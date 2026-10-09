import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';

abstract final class MockSafety {
  static final List<MockRoute> routes = [
    MockRoute.get(SafetyEndpoints.centre, _centre),
    MockRoute.post(SafetyEndpoints.sos, _startSos),
    MockRoute.get(SafetyEndpoints.sosById, (request) => _sosPayload(_requireSos(request))),
    MockRoute.post(SafetyEndpoints.sosEnd, _endSos),
    MockRoute.get(SafetyEndpoints.contacts, (_) => _contactsPayload()),
    MockRoute.post(SafetyEndpoints.contacts, _addContact),
    MockRoute.delete(SafetyEndpoints.contactById, _removeContact),
    MockRoute.post(SafetyEndpoints.reports, _report),
  ];

  static const int _maxContacts = 5;
  static const int _graceSeconds = 5;
  static const String _emergencyNumber = '112';
  static const Duration _alertedFor = Duration(seconds: 10);
  static const int _minDetailsLength = 10;
  static const List<String> _reportCategories = ['driving', 'harassment', 'vehicle', 'route', 'other'];
  static final RegExp _nigerianNumber = RegExp(r'^\+234[789]\d{9}$');

  static final List<Map<String, dynamic>> _contacts = [
    {'id': 'ct_1', 'name': 'Alex Johnson', 'phone': '+2348031234567'},
    {'id': 'ct_2', 'name': 'Ebuka Samson', 'phone': '+2348052345678'},
  ];
  static final Map<String, _MockSos> _sosRecords = {};
  static int _contactCount = 2;
  static int _reportCount = 0;

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static String _digits(Object? phone) => (phone as String? ?? '').replaceAll(RegExp(r'\D'), '');

  static Map<String, dynamic> _contactsPayload() => {
    'contacts': [for (final contact in _contacts) Map<String, dynamic>.of(contact)],
    'maxContacts': _maxContacts,
  };

  static Object? _centre(MockRequest request) {
    final trip = _tripBlock(request.query['tripId'] as String?);
    final active = _activeSos();
    return {
      ..._contactsPayload(),
      'sosGraceSeconds': _graceSeconds,
      'emergencyNumber': _emergencyNumber,
      'activeSos': active == null ? null : _sosPayload(active),
      'trip': trip,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static bool _isLive(String id) {
    final status = MockTrip.statusOf(id);
    return status != 'completed' && status != 'cancelled';
  }

  static String? _liveTripId(String? requested) {
    if (requested != null && MockTripState.trips.containsKey(requested) && _isLive(requested)) return requested;
    for (final id in MockTripState.trips.keys.toList().reversed) {
      if (_isLive(id)) return id;
    }
    return null;
  }

  static String _titled(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  static String _areaOf(Map<String, dynamic> place) {
    final address = place['address'] as String? ?? '';
    return address.isEmpty ? place['name'] as String : address;
  }

  static Map<String, dynamic>? _tripBlock(String? requested) {
    final id = _liveTripId(requested);
    if (id == null) return null;
    final payload = MockTrip.payload(id);
    final driver = payload['driver'] as Map<String, dynamic>;
    final vehicle = payload['vehicle'] as Map<String, dynamic>;
    final pickup = payload['pickup'] as Map<String, dynamic>;
    final dropoff = payload['dropoff'] as Map<String, dynamic>;
    final isHeadingToPickup = const {'driver_en_route', 'driver_arrived', 'pin_verified'}.contains(payload['status']);
    final pending = MockTrip.pendingStops(id);
    final currentPlace = isHeadingToPickup ? pickup : (pending.isEmpty ? dropoff : pending.first);
    return {
      'id': id,
      'reference': 'SR-${10000000 + id.hashCode.abs() % 90000000}',
      'isLive': true,
      'counterpartName': driver['name'],
      'counterpartRole': 'driver',
      'vehicle':
          '${vehicle['make']} ${vehicle['model']} · ${_titled(vehicle['colour'] as String)} · ${vehicle['plate']}',
      'pickup': pickup['name'],
      'dropoff': dropoff['name'],
      'currentArea': _areaOf(currentPlace),
      'startedAt': _iso(MockTrip.createdAt(id)),
    };
  }

  static String? get activeSosId => _activeSos()?.id;

  static void reset() => _sosRecords.clear();

  static _MockSos? _activeSos() {
    for (final record in _sosRecords.values) {
      if (record.endedAt == null) return record;
    }
    return null;
  }

  static Map<String, dynamic> _sosPayload(_MockSos record) {
    final now = DateTime.now();
    final isMonitoring = now.difference(record.startedAt) >= _alertedFor;
    return {
      'id': record.id,
      'status': record.endedAt == null ? 'active' : 'ended',
      'startedAt': _iso(record.startedAt),
      'liveLocation': record.hasLocation,
      'contactsNotified': record.contactsNotified,
      'safetyTeam': isMonitoring ? 'monitoring' : 'alerted',
      'serverTime': _iso(now),
    };
  }

  static _MockSos _requireSos(MockRequest request) {
    final record = _sosRecords[request.params['id']];
    if (record == null) throw const MockFailure(404, 'We can’t find that SOS.');
    return record;
  }

  static bool _isValidCoordinate(Object? lat, Object? lng) =>
      lat is num && lng is num && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  static Object? _startSos(MockRequest request) {
    final running = _activeSos();
    if (running != null) {
      throw MockFailure(
        409,
        'You already have an SOS running.',
        code: 'sos_already_active',
        data: {'sos': _sosPayload(running)},
      );
    }
    final lat = request.body['lat'];
    final lng = request.body['lng'];
    final hasCoordinates = lat != null || lng != null;
    if (hasCoordinates && !_isValidCoordinate(lat, lng)) {
      throw const MockFailure(422, 'We couldn’t find your location.', code: 'location_unavailable');
    }
    final record = _MockSos(
      id: 'sos_${_sosRecords.length + 1}',
      startedAt: DateTime.now(),
      hasLocation: hasCoordinates,
      contactsNotified: _contacts.length,
    );
    _sosRecords[record.id] = record;
    return _sosPayload(record);
  }

  static Object? _endSos(MockRequest request) {
    final record = _requireSos(request);
    final endedAt = record.endedAt ??= DateTime.now();
    return {'id': record.id, 'status': 'ended', 'endedAt': _iso(endedAt), 'serverTime': _iso(DateTime.now())};
  }

  static Object? _addContact(MockRequest request) {
    final phone = request.body['phone'] as String? ?? '';
    final name = (request.body['name'] as String? ?? '').trim();
    if (!_nigerianNumber.hasMatch(phone)) {
      throw const MockFailure(422, 'That number doesn’t look right.', code: 'invalid_phone');
    }
    if (_digits(phone) == _digits(MockData.user['phone'])) {
      throw const MockFailure(422, 'That’s your own number.', code: 'own_number');
    }
    if (name.isEmpty) throw const MockFailure(422, 'Add a name for this contact.');
    if (_contacts.any((contact) => contact['phone'] == phone)) {
      throw const MockFailure(409, 'That person is already a contact.', code: 'duplicate_contact');
    }
    if (_contacts.length >= _maxContacts) {
      throw const MockFailure(409, 'You’ve reached the contacts limit.', code: 'contacts_limit');
    }
    final contact = {'id': 'ct_${++_contactCount}', 'name': name, 'phone': phone};
    _contacts.add(contact);
    return Map<String, dynamic>.of(contact);
  }

  static Object? _removeContact(MockRequest request) {
    final id = request.params['id']!;
    final index = _contacts.indexWhere((contact) => contact['id'] == id);
    if (index < 0) throw const MockFailure(404, 'We can’t find that contact.');
    _contacts.removeAt(index);
    return {'id': id, 'deleted': true};
  }

  static Object? _report(MockRequest request) {
    final category = request.body['category'];
    final details = (request.body['details'] as String? ?? '').trim();
    if (!_reportCategories.contains(category)) throw const MockFailure(422, 'Pick what happened.');
    if (details.length < _minDetailsLength) {
      throw const MockFailure(422, 'Tell us a little more.', code: 'details_too_short');
    }
    _reportCount++;
    return {
      'id': 'rep_$_reportCount',
      'status': 'received',
      'reference': 'SF-${1041 + _reportCount}',
      'serverTime': _iso(DateTime.now()),
    };
  }
}

class _MockSos {
  _MockSos({required this.id, required this.startedAt, required this.hasLocation, required this.contactsNotified});

  final String id;
  final DateTime startedAt;
  final bool hasLocation;
  final int contactsNotified;
  DateTime? endedAt;
}
