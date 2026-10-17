import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/core/api/mock/mock_wallet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class MockTripWrapUp {
  static final List<MockRoute> routes = [
    MockRoute.get(AppEndpoints.tripPayment, _payment),
    MockRoute.post(AppEndpoints.tripPayment, _pay),
    MockRoute.post(AppEndpoints.tripPaymentCancel, _cancelPayment),
    MockRoute.get(AppEndpoints.tripReceipt, _receipt),
    MockRoute.post(AppEndpoints.tripRating, _rate),
  ];

  static const Duration _cashConfirmDelay = Duration(seconds: 4);
  static const int _fallbackFare = 4500;
  static const double _fallbackDistanceKm = 12.4;
  static const int _fallbackDurationMinutes = 24;
  static const List<String> _allowedMethods = ['cash', 'wallet'];
  static const List<String> _ratingTags = [
    'FAST_AND_POLITE',
    'CLEAN_CAR',
    'GREAT_CONVERSATION',
    'SAFE_DRIVING',
    'ON_TIME',
    'EXPERT_NAVIGATION',
    'LATE_ARRIVAL',
    'UNSAFE_DRIVING',
    'RUDE',
    'DIRTY_CAR',
    'WRONG_ROUTE',
  ];

  static Duration cashConfirmDelay = _cashConfirmDelay;
  static Duration cashWaitWindow = const Duration(seconds: 90);

  static bool isSettled(String id) =>
      MockTripState.paidAt.containsKey(id) || MockTripState.cashPostedAt.containsKey(id);

  static bool isRated(String id) => MockTripState.ratings.containsKey(id);

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
    final posted = MockTripState.cashPostedAt[id];
    if (posted == null) return null;
    final confirmedAt = posted.add(cashConfirmDelay);
    return DateTime.now().isBefore(confirmedAt) ? null : confirmedAt;
  }

  static void _settle(String id, String method, DateTime at) {
    MockTripState.paidAt.putIfAbsent(id, () => at);
    MockTripState.paymentMethod[id] = method;
    MockTripState.lastMethod = method;
  }

  static num _amount(num naira) => MockMoney.of(naira).major;

  static Map<String, dynamic> _paymentPayload(
    String id,
    Map<String, dynamic> trip,
    String status, {
    String? method,
    DateTime? paidAt,
    DateTime? cashWaitExpiresAt,
  }) => {
    'rideId': id,
    'amount': _amount(_fareOf(trip)),
    'currency': MockMoney.currency,
    'status': status,
    'method': method ?? 'wallet',
    'allowedMethods': _allowedMethods,
    'paidAt': paidAt?.toUtc().toIso8601String(),
    'cashWaitExpiresAt': cashWaitExpiresAt?.toUtc().toIso8601String(),
  };

  static Object? _payment(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    final paidAt = MockTripState.paidAt[id];
    final method = MockTripState.paymentMethod[id];
    if (paidAt != null && method != null) {
      return _paymentPayload(id, trip, 'succeeded', method: method, paidAt: paidAt);
    }
    final postedAt = MockTripState.cashPostedAt[id];
    if (postedAt != null) {
      final confirmedAt = _cashConfirmedAt(id);
      if (confirmedAt != null) {
        _settle(id, 'cash', confirmedAt);
        return _paymentPayload(id, trip, 'succeeded', method: 'cash', paidAt: confirmedAt);
      }
      final deadline = postedAt.add(cashWaitWindow);
      if (DateTime.now().isAfter(deadline)) {
        MockTripState.cashPostedAt.remove(id);
        return _paymentPayload(id, trip, 'pending');
      }
      return _paymentPayload(id, trip, 'awaiting_driver', method: 'cash', cashWaitExpiresAt: deadline);
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
      'wallet' => _payWallet(id, trip),
      _ => throw const MockFailure(422, 'Pick a way to pay.', code: 'invalid_method'),
    };
  }

  static Object? _payCash(String id, Map<String, dynamic> trip) {
    MockTripState.cashPostedAt[id] = DateTime.now();
    return _paymentPayload(
      id,
      trip,
      'awaiting_driver',
      method: 'cash',
      cashWaitExpiresAt: MockTripState.cashPostedAt[id]!.add(cashWaitWindow),
    );
  }

  static Object? _payWallet(String id, Map<String, dynamic> trip) {
    final paidAt = DateTime.now();
    MockWallet.payTrip(
      tripId: id,
      fare: _fareOf(trip),
      pickup: _placeOf(trip['pickup'], 'Pickup')['name'] as String,
      dropoff: _placeOf(trip['dropoff'], 'Drop off')['name'] as String,
      at: paidAt,
      itemName: MockTrip.deliveryItemName(id),
    );
    MockTripState.cashPostedAt.remove(id);
    _settle(id, 'wallet', paidAt);
    return _paymentPayload(id, trip, 'succeeded', method: 'wallet', paidAt: paidAt);
  }

  static Object? _cancelPayment(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    if (MockTripState.paidAt.containsKey(id)) {
      throw const MockFailure(409, 'This trip is already paid.', code: 'already_paid');
    }
    MockTripState.cashPostedAt.remove(id);
    return _paymentPayload(id, trip, 'pending');
  }

  static int _roundedShare(int fare, double share) => ((fare * share) / 50).round() * 50;

  static ({int base, int distance, int time, int service}) _splitFare(int fare) {
    var base = _roundedShare(fare, 0.22);
    final distance = _roundedShare(fare, 0.44);
    final time = _roundedShare(fare, 0.22);
    var service = fare - base - distance - time;
    if (service < 0) {
      base += service;
      service = 0;
    }
    return (base: base, distance: distance, time: time, service: service);
  }

  static List<Map<String, dynamic>> _fareLines(int fare, double distanceKm, int durationMinutes) {
    final split = _splitFare(fare);
    return [
      {'code': 'BASE_FARE', 'label': 'Base fare', 'amount': _amount(split.base)},
      {
        'code': 'DISTANCE',
        'label': 'Distance (${SangaDistance.fromKilometers(distanceKm)})',
        'amount': _amount(split.distance),
        'quantity': distanceKm,
        'unit': 'km',
        'rate': _amount(distanceKm == 0 ? 0 : (split.distance / distanceKm).round()),
      },
      {
        'code': 'TIME',
        'label': 'Time ($durationMinutes mins)',
        'amount': _amount(split.time),
        'quantity': durationMinutes,
        'unit': 'min',
        'rate': _amount(durationMinutes == 0 ? 0 : (split.time / durationMinutes).round()),
      },
    ];
  }

  static List<Map<String, dynamic>> _adjustments(int fare) {
    final service = _splitFare(fare).service;
    return [
      if (service > 0) {'code': 'SERVICE_FEE', 'label': 'Service fee', 'amount': _amount(service)},
    ];
  }

  static Map<String, dynamic> _placeOf(Object? value, String fallbackName) {
    final place = _asMap(value);
    final name = place['name'] as String? ?? fallbackName;
    return {'name': name, 'address': place['address'] as String? ?? name};
  }

  static Map<String, dynamic> _receiptPlaceOf(Object? value, String fallbackName) {
    final place = _asMap(value);
    return {
      'address': _placeOf(value, fallbackName)['address'],
      'latitude': place['latitude'],
      'longitude': place['longitude'],
    };
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
      'plateNumber': vehicle['plateNumber'] ?? vehicle['plate'],
      'featureLabels': vehicle['featureLabels'] ?? vehicle['features'] ?? const <String>[],
    };
  }

  static Map<String, dynamic> _receiptVehicleOf(Map<String, dynamic> trip) {
    final vehicle = _vehicleOf(trip);
    return {'display': '(${vehicle['year']} model) REG NO: ${vehicle['plateNumber']}', 'vehicleType': 'car'};
  }

  static Map<String, dynamic> _receiptDriverOf(Map<String, dynamic> trip) {
    final driver = _driverOf(trip);
    return {
      'id': driver['id'],
      'name': driver['name'],
      'photoUrl': driver['photoUrl'],
      'ridesCompleted': driver['ridesCompleted'],
      'rating': driver['rating'],
    };
  }

  static Map<String, dynamic> _paidWithOf(String id) {
    final method = MockTripState.paymentMethod[id] ?? 'cash';
    return {
      'method': method,
      'status': 'succeeded',
      'brand': null,
      'last4': null,
      'display': method == 'wallet' ? 'Wallet' : 'Cash',
      'paidAt': (MockTripState.paidAt[id] ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  static double _distanceOf(Map<String, dynamic> trip) =>
      (trip['distanceKm'] as num?)?.toDouble() ?? _fallbackDistanceKm;

  static int _durationOf(Map<String, dynamic> trip) =>
      (trip['durationMinutes'] as num?)?.toInt() ?? _fallbackDurationMinutes;

  static String _categoryOf(Map<String, dynamic> trip) =>
      _asMap(trip['vehicle'])['category'] as String? ?? trip['category'] as String? ?? 'go';

  static String _referenceOf(String id, {required bool isDelivery}) =>
      '${isDelivery ? 'DL' : 'SR'}-${id.hashCode.abs() % 90000000 + 10000000}';

  static Object? _receipt(MockRequest request) => _receiptOf(request.params['id']!, _tripOf(request));

  static Map<String, dynamic> _receiptOf(String id, Map<String, dynamic> trip) {
    final fare = _fareOf(trip);
    final distanceKm = _distanceOf(trip);
    final durationMinutes = _durationOf(trip);
    final paidWith = _paidWithOf(id);
    final delivery = MockTrip.deliveryReceiptBlock(id);
    return {
      'rideId': id,
      'reference': _referenceOf(id, isDelivery: delivery != null),
      'kind': delivery == null ? 'ride' : 'delivery',
      'status': 'completed',
      'statusLabel': 'Completed',
      'title': delivery == null ? 'Trip receipt' : 'Delivery receipt',
      'pickup': _receiptPlaceOf(trip['pickup'], 'Pickup'),
      'dropoff': _receiptPlaceOf(trip['dropoff'], 'Drop off'),
      'distanceKm': distanceKm,
      'distanceDisplay': SangaDistance.fromKilometers(distanceKm),
      'durationMin': durationMinutes,
      'durationDisplay': durationMinutes == 1 ? '1 minute' : '$durationMinutes minutes',
      'lines': _fareLines(fare, distanceKm, durationMinutes),
      'adjustments': _adjustments(fare),
      'totalPaid': _amount(fare),
      'totalLabel': 'TOTAL PAID',
      'tip': 0,
      'payment': paidWith,
      'completedAt': paidWith['paidAt'],
      'driver': _receiptDriverOf(trip),
      'vehicle': _receiptVehicleOf(trip),
      'delivery': ?delivery,
    };
  }

  static Map<String, dynamic> historyDetail(String id) {
    final trip = MockTripState.trips[id] ?? const <String, dynamic>{};
    final live = MockTrip.payload(id);
    final fare = _fareOf(trip);
    final distanceKm = _distanceOf(trip);
    final durationMinutes = _durationOf(trip);
    final delivery = _asMap(live['delivery']);
    final isDelivery = delivery.isNotEmpty;
    final item = _asMap(delivery['item']);
    final proof = _asMap(delivery['deliveryProof']);
    final occurredAt = MockTrip.completedAt(id) ?? DateTime.now();
    final stars = MockTripState.ratings[id];
    return {
      'id': id,
      'kind': isDelivery ? 'delivery' : 'ride',
      'status': 'completed',
      'category': _categoryOf(trip),
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'pickup': live['pickup'],
      'stops': [
        for (final stop in live['stops'] as List) {..._asMap(stop)}..remove('status'),
      ],
      'dropoff': live['dropoff'],
      'fare': _amount(fare),
      'returnFee': ?live['returnFee'],
      if (isDelivery) 'itemName': item['name'],
      'reference': _referenceOf(id, isDelivery: isDelivery),
      'requestedAt': MockTrip.createdAt(id).toUtc().toIso8601String(),
      'counterOffer': MockMoney.jsonOrNull(trip['counterOffer'] as num?),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'lines': [..._fareLines(fare, distanceKm, durationMinutes), ..._adjustments(fare)],
      'paidWith': _paidWithOf(id),
      'driver': {...live['driver'] as Map<String, dynamic>, 'blocked': false},
      'vehicle': _vehicleOf(trip),
      'events': _historyEvents(live['events'] as List, isDelivery: isDelivery),
      'rating': stars == null ? null : {'stars': stars},
      'cancellation': null,
      'delivery': isDelivery
          ? {
              'tier': delivery['tier'],
              'kind': delivery['kind'],
              'item': item,
              'recipient': delivery['recipient'],
              'deliveryProof': proof.isEmpty ? null : {'photoUrl': proof['photoUrl'], 'at': proof['at']},
            }
          : null,
    };
  }

  static List<Map<String, dynamic>> _historyEvents(List<dynamic> events, {required bool isDelivery}) {
    final codes = {
      'driver_accepted': 'driver_accepted',
      'driver_arrived': 'driver_arrived',
      'trip_started': isDelivery ? 'package_picked_up' : 'trip_started',
      'arrived_dropoff': 'arrived_dropoff',
      'trip_completed': isDelivery ? 'package_delivered' : 'trip_completed',
    };
    return [
      for (final event in events.map(_asMap))
        if (codes[event['type']] case final code?) {'type': code, 'at': event['at']},
    ];
  }

  static Object? _rate(MockRequest request) {
    final id = request.params['id']!;
    final trip = _tripOf(request);
    final stars = (request.body['stars'] as num?)?.toInt() ?? 0;
    if (stars < 1 || stars > 5) throw const MockFailure(422, 'Pick between 1 and 5 stars.', code: 'invalid_stars');
    final tags = request.body['tags'];
    if (tags != null && (tags is! List || tags.any((tag) => !_ratingTags.contains(tag)))) {
      throw const MockFailure(422, 'Pick tags from the list.', code: 'invalid_tags');
    }
    if (MockTripState.ratings.containsKey(id)) {
      throw const MockFailure(409, 'You already rated this trip.', code: 'already_rated');
    }
    MockTripState.ratings[id] = stars;
    final driver = _receiptDriverOf(trip);
    return {
      'id': 'rating_$id',
      'rideId': id,
      'stars': stars,
      'review': request.body['review'],
      'tags': tags ?? const <String>[],
      'driver': {'id': driver['id'], 'name': driver['name'], 'rating': driver['rating']},
      'createdAt': _isoNow(),
    };
  }
}
