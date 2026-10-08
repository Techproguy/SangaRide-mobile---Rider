import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/core/api/mock/mock_wallet.dart';

abstract final class MockTripWrapUp {
  static final List<MockRoute> routes = [
    MockRoute.get(MockEndpoints.tripPayment, _payment),
    MockRoute.post(MockEndpoints.tripPayment, _pay),
    MockRoute.post(MockEndpoints.tripPaymentCancel, _cancelPayment),
    MockRoute.get(MockEndpoints.tripReceipt, _receipt),
    MockRoute.post(MockEndpoints.tripRating, _rate),
  ];

  static const Duration _cashConfirmDelay = Duration(seconds: 4);
  static const int _fallbackFare = 4500;
  static const double _fallbackDistanceKm = 12.4;
  static const int _fallbackDurationMinutes = 24;
  static const List<String> _allowedMethods = ['cash', 'card', 'wallet'];

  static final Map<String, DateTime> _cashPostedAt = {};
  static final Map<String, String> _cardLast4 = {};
  static final Map<String, int> _ratings = {};
  static String? _lastMethod;

  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<String, dynamic> _tripOf(MockRequest request) {
    final id = request.params['id']!;
    final trip = MockTripState.trips[id];
    if (trip == null && MockTripState.trips.isNotEmpty) {
      throw const MockFailure(404, 'We can’t find that trip.', code: 'trip_not_found');
    }
    return trip ?? const {};
  }

  static int _fareOf(Map<String, dynamic> trip) => (trip['fare'] as num?)?.toInt() ?? _fallbackFare;

  static DateTime? _cashConfirmedAt(String id) {
    final posted = _cashPostedAt[id];
    if (posted == null) return null;
    final confirmedAt = posted.add(_cashConfirmDelay);
    return DateTime.now().isBefore(confirmedAt) ? null : confirmedAt;
  }

  static void _settle(String id, String method, DateTime at) {
    MockTripState.paidAt.putIfAbsent(id, () => at);
    MockTripState.paymentMethod[id] = method;
    _lastMethod = method;
  }

  static Map<String, dynamic> _paymentPayload(
    String id,
    Map<String, dynamic> trip,
    String status, {
    String? method,
    String? last4,
    DateTime? paidAt,
  }) => {
    'tripId': id,
    'status': status,
    'amount': _fareOf(trip),
    'currency': 'NGN',
    'method': method,
    'last4': last4,
    'paidAt': paidAt?.toUtc().toIso8601String(),
    'allowedMethods': _allowedMethods,
    'lastMethod': _lastMethod,
    'serverTime': _isoNow(),
  };

  static Object? _payment(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    final paidAt = MockTripState.paidAt[id];
    final method = MockTripState.paymentMethod[id];
    if (paidAt != null && method != null) {
      return _paymentPayload(id, trip, 'succeeded', method: method, last4: _cardLast4[id], paidAt: paidAt);
    }
    if (_cashPostedAt.containsKey(id)) {
      final confirmedAt = _cashConfirmedAt(id);
      if (confirmedAt == null) return _paymentPayload(id, trip, 'awaiting_driver', method: 'cash');
      _settle(id, 'cash', confirmedAt);
      return _paymentPayload(id, trip, 'succeeded', method: 'cash', paidAt: confirmedAt);
    }
    return _paymentPayload(id, trip, 'pending');
  }

  static Object? _pay(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    if (MockTripState.paidAt.containsKey(id)) {
      throw const MockFailure(409, 'This trip is already paid.', code: 'already_paid');
    }
    final method = request.body['method'];
    return switch (method) {
      'cash' => _payCash(id, trip),
      'card' => _payCard(id, trip, _asMap(request.body['card'])),
      'wallet' => _payWallet(id, trip),
      _ => throw const MockFailure(422, 'Pick a way to pay.', code: 'invalid_method'),
    };
  }

  static Object? _payCash(String id, Map<String, dynamic> trip) {
    _cashPostedAt[id] = DateTime.now();
    return _paymentPayload(id, trip, 'awaiting_driver', method: 'cash');
  }

  static Object? _payCard(String id, Map<String, dynamic> trip, Map<String, dynamic> card) {
    final number = (card['number'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final expiry = card['expiry'] as String? ?? '';
    final cvv = card['cvv'] as String? ?? '';
    final pin = card['pin'] as String? ?? '';
    if (!_isFutureExpiry(expiry)) throw const MockFailure(402, 'This card has expired.', code: 'card_expired');
    if (number.length < 13 || cvv.length != 3 || pin.length != 4) {
      throw const MockFailure(422, 'Check your card details.', code: 'invalid_card');
    }
    if (number.endsWith('0002')) {
      throw const MockFailure(402, 'Your bank declined this card.', code: 'card_declined');
    }
    final last4 = number.substring(number.length - 4);
    final paidAt = DateTime.now();
    _cashPostedAt.remove(id);
    _cardLast4[id] = last4;
    _settle(id, 'card', paidAt);
    return _paymentPayload(id, trip, 'succeeded', method: 'card', last4: last4, paidAt: paidAt);
  }

  static Object? _payWallet(String id, Map<String, dynamic> trip) {
    final paidAt = DateTime.now();
    MockWallet.payTrip(
      tripId: id,
      fare: _fareOf(trip),
      pickup: _placeOf(trip['pickup'], 'Pickup')['name'] as String,
      dropoff: _placeOf(trip['dropoff'], 'Drop off')['name'] as String,
      at: paidAt,
    );
    _cashPostedAt.remove(id);
    _settle(id, 'wallet', paidAt);
    return _paymentPayload(id, trip, 'succeeded', method: 'wallet', paidAt: paidAt);
  }

  static bool _isFutureExpiry(String expiry) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry);
    if (match == null) return false;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    return DateTime(year, month + 1).isAfter(DateTime(now.year, now.month));
  }

  static Object? _cancelPayment(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    if (MockTripState.paidAt.containsKey(id)) {
      throw const MockFailure(409, 'This trip is already paid.', code: 'already_paid');
    }
    _cashPostedAt.remove(id);
    return _paymentPayload(id, trip, 'pending');
  }

  static int _roundedShare(int fare, double share) => ((fare * share) / 50).round() * 50;

  static List<Map<String, dynamic>> _fareLines(int fare, double distanceKm, int durationMinutes) {
    var base = _roundedShare(fare, 0.22);
    final distance = _roundedShare(fare, 0.44);
    final time = _roundedShare(fare, 0.22);
    var service = fare - base - distance - time;
    if (service < 0) {
      base += service;
      service = 0;
    }
    final km = distanceKm.toStringAsFixed(1);
    return [
      {'key': 'base_fare', 'label': 'Base fare', 'amount': base},
      {'key': 'distance', 'label': 'Distance ($km km)', 'amount': distance},
      {'key': 'time', 'label': 'Time ($durationMinutes mins)', 'amount': time},
      {'key': 'service_fee', 'label': 'Service fee', 'amount': service},
    ];
  }

  static Map<String, dynamic> _placeOf(Object? value, String fallbackName) {
    final place = _asMap(value);
    final name = place['name'] as String? ?? fallbackName;
    return {'name': name, 'address': place['address'] as String? ?? name};
  }

  static Map<String, dynamic> _driverOf(Map<String, dynamic> trip) {
    final fallback = _asMap(MockData.driverOffers.first['driver']);
    final driver = {...fallback, ..._asMap(trip['driver'])};
    return {
      'id': driver['id'] ?? 'drv_kamaru',
      'name': driver['name'],
      'firstName': driver['firstName'],
      'photoUrl': driver['photoUrl'],
      'verified': driver['verified'] ?? true,
      'rating': driver['rating'],
      'ridesCompleted': driver['ridesCompleted'],
    };
  }

  static Map<String, dynamic> _vehicleOf(Map<String, dynamic> trip) {
    final vehicle = {...MockData.driverVehicle, ..._asMap(trip['vehicle'])};
    return {
      'make': vehicle['make'],
      'model': vehicle['model'],
      'year': vehicle['year'],
      'colour': vehicle['colour'],
      'plate': vehicle['plate'],
      'features': vehicle['features'] ?? const <String>[],
    };
  }

  static Object? _receipt(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    final fare = _fareOf(trip);
    final distanceKm = (trip['distanceKm'] as num?)?.toDouble() ?? _fallbackDistanceKm;
    final durationMinutes = (trip['durationMinutes'] as num?)?.toInt() ?? _fallbackDurationMinutes;
    final method = MockTripState.paymentMethod[id] ?? 'cash';
    final stars = _ratings[id];
    return {
      'id': 'rcpt_$id',
      'tripId': id,
      'status': 'completed',
      'serverTime': _isoNow(),
      'pickup': _placeOf(trip['pickup'], 'Pickup'),
      'dropoff': _placeOf(trip['dropoff'], 'Drop off'),
      'stops': [for (final stop in (trip['stops'] as List? ?? const [])) _placeOf(stop, 'Stop')],
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'lines': _fareLines(fare, distanceKm, durationMinutes),
      'total': fare,
      'paidWith': {'method': method, 'last4': method == 'card' ? _cardLast4[id] : null},
      'paidAt': (MockTripState.paidAt[id] ?? DateTime.now()).toUtc().toIso8601String(),
      'driver': _driverOf(trip),
      'vehicle': _vehicleOf(trip),
      'category': _asMap(trip['vehicle'])['category'] ?? trip['category'] ?? 'go',
      'rating': stars == null ? null : {'stars': stars},
      'delivery': ?MockTrip.deliveryReceiptBlock(id),
    };
  }

  static Object? _rate(MockRequest request) {
    final id = request.params['id']!;
    _tripOf(request);
    final stars = (request.body['stars'] as num?)?.toInt() ?? 0;
    if (stars < 1 || stars > 5) throw const MockFailure(422, 'Pick between 1 and 5 stars.', code: 'invalid_stars');
    if (_ratings.containsKey(id)) {
      throw const MockFailure(409, 'You already rated this trip.', code: 'already_rated');
    }
    _ratings[id] = stars;
    return {'tripId': id, 'stars': stars, 'serverTime': _isoNow()};
  }
}
