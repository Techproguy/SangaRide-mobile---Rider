import 'dart:math' as math;

import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class MockHistory {
  static final List<MockRoute> routes = [
    MockRoute.get(HistoryEndpoints.rides, _list),
    MockRoute.get(HistoryEndpoints.blockedDrivers, (_) => _blockedList()),
    MockRoute.post(HistoryEndpoints.blockedDrivers, _block),
    MockRoute.delete(HistoryEndpoints.blockedDriver, _unblock),
  ];

  static const int _count = 30;
  static const int _defaultLimit = 20;
  static const int _maxLimit = 50;
  static const Set<String> _listStatuses = {
    'scheduled',
    'requested',
    'accepted',
    'driver_arrived',
    'in_progress',
    'arrived_at_dropoff',
    'completed',
    'cancelled',
    'no_driver_found',
  };
  static const int _minutesBetweenTrips = 1290;
  static const int _cancellationFee = 300;
  static const String _proofAsset = 'assets/images/service_delivery.webp';
  static const String _packagePhotoAsset = 'assets/images/delivery_pickup_proof.webp';

  static final DateTime _anchor = DateTime.now();
  static final Map<String, DateTime> _blockedDrivers = {};
  static final Map<String, Map<String, dynamic> Function()> _recorded = {};

  static void recordTrip(String id, Map<String, dynamic> Function() detailOf) => _recorded[id] = detailOf;

  static List<Map<String, dynamic>> _recordedWith(String status) => [
    for (final detailOf in _recorded.values.toList().reversed)
      if (detailOf() case final detail when detail['status'] == status) detail,
  ];

  static const List<String> _stopIds = [
    'mock_cr_ikeja',
    'mock_cr_idumota',
    'mock_palms',
    'mock_yabatech',
    'mock_icm',
    'mock_eko',
    'mock_unilag',
    'mock_airport',
    'mock_home',
    'mock_work',
  ];

  static const List<String> _categories = ['go', 'plus', 'go', 'xl', 'lux', 'moto', 'go', 'plus'];
  static const Map<String, int> _ratePerKm = {'go': 1500, 'plus': 2000, 'xl': 3000, 'lux': 5000, 'moto': 700};

  static const List<Map<String, dynamic>> _vehicles = [
    {'make': 'Toyota', 'model': 'Corolla', 'year': 2007, 'colour': 'blue', 'plate': 'BDJ822FQ'},
    {'make': 'Honda', 'model': 'Accord', 'year': 2012, 'colour': 'silver', 'plate': 'KJA415XY'},
    {'make': 'Toyota', 'model': 'Camry', 'year': 2015, 'colour': 'black', 'plate': 'LSD093AB'},
    {'make': 'Lexus', 'model': 'RX 350', 'year': 2016, 'colour': 'white', 'plate': 'EKY660GH'},
  ];

  static const List<Map<String, String>> _items = [
    {
      'name': 'Food',
      'description': 'Food on a plate inside a paper bag. Handle with care and keep it upright.',
      'size': 'Small box',
      'weight': '~2kg',
    },
    {
      'name': 'Documents',
      'description': 'A sealed brown envelope with signed contracts.',
      'size': 'Envelope',
      'weight': '~0.5kg',
    },
    {
      'name': 'Birthday gift',
      'description': 'Wrapped gift box. Please keep it flat.',
      'size': 'Medium box',
      'weight': '~3kg',
    },
    {'name': 'Phone charger', 'description': 'Small pouch with a fast charger.', 'size': 'Small box', 'weight': '~1kg'},
    {'name': 'Groceries', 'description': 'Two bags of groceries, one has eggs.', 'size': 'Large box', 'weight': '~8kg'},
    {'name': 'Shoes', 'description': 'Boxed sneakers.', 'size': 'Medium box', 'weight': '~2kg'},
  ];

  static const List<Map<String, String>> _recipients = [
    {'name': 'Oladimeji Samuel', 'phone': '8015901779'},
    {'name': 'Ajani Toluwanimi', 'phone': '8054308337'},
    {'name': 'Lawal James Israel', 'phone': '8146234260'},
  ];

  static const List<String> _cardLast4 = ['4242', '1881', '0910'];
  static const List<int> _stars = [5, 4, 5, 3, 5];

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static bool _isDelivery(int i) => i % 4 == 1;

  static bool _isCancelled(int i) => i % 6 == 4 || i == 13;

  static String _cancelledBy(int i) => const ['driver', 'rider', 'system'][i % 3];

  static String _idOf(int i) => 'hist_${i.toString().padLeft(2, '0')}';

  static bool isPaidWithWallet(String id) {
    final i = _indexOf(id);
    return i != null && !_isCancelled(i) && i % 5 != 0;
  }

  static int? _indexOf(String id) {
    final match = RegExp(r'^hist_(\d{2})$').firstMatch(id);
    final index = match == null ? null : int.parse(match.group(1)!);
    return index != null && index < _count ? index : null;
  }

  static DateTime _occurredAt(int i) =>
      _anchor.subtract(Duration(minutes: 40 + i * _minutesBetweenTrips + (i % 4) * 45));

  static Map<String, dynamic> _stop(int index) => MockRegion.place(_stopIds[index % _stopIds.length]);

  static List<Map<String, dynamic>> _stopsOf(int i) => [if (i % 7 == 3) _stop(i * 3 + 1)];

  static Map<String, dynamic> _pickup(int i) => _stop(i * 3);

  static Map<String, dynamic> _dropoff(int i) => _stop(i * 3 + 2 + i % 3);

  static double _km(int i) {
    final points = [_pickup(i), ..._stopsOf(i), _dropoff(i)].map((place) => place['coordinates'] as Map).toList();
    var km = 0.0;
    for (var leg = 1; leg < points.length; leg++) {
      km += _distanceKm(points[leg - 1], points[leg]);
    }
    return double.parse((km * 1.3).clamp(1.5, 60).toStringAsFixed(1));
  }

  static double _distanceKm(Map a, Map b) {
    const earthRadiusKm = 6371.0;
    double radians(num degrees) => degrees * math.pi / 180;
    final dLat = radians((b['lat'] as num) - (a['lat'] as num));
    final dLng = radians((b['lng'] as num) - (a['lng'] as num));
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(a['lat'] as num)) * math.cos(radians(b['lat'] as num)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  static int _roundedToFifty(num value) => (value / 50).round() * 50;

  static String _categoryOf(int i) => _isDelivery(i) ? 'go' : _categories[i % _categories.length];

  static int _fareOf(int i) {
    final km = _km(i);
    if (_isDelivery(i)) return _roundedToFifty(1200 + km * 220);
    return _roundedToFifty(800 + km * _ratePerKm[_categoryOf(i)]! * 0.25);
  }

  static int _minutesOf(int i) => (_km(i) * 2.6 + 8).round();

  static Map<String, dynamic> _driverOf(int i) {
    final drivers = [for (final offer in MockData.driverOffers) offer['driver'] as Map<String, dynamic>];
    return drivers[i % drivers.length];
  }

  static Map<String, dynamic> _vehicleOf(int i) {
    final vehicle = _vehicles[i % _vehicles.length];
    return {
      ...vehicle,
      'plate': MockRegion.plate(vehicle['plate'] as String),
      'features': const ['Air conditioned'],
    };
  }

  static Map<String, dynamic> _summary(int i) => {
    'id': _idOf(i),
    'kind': _isDelivery(i) ? 'delivery' : 'ride',
    'status': _isCancelled(i) ? 'cancelled' : 'completed',
    'category': _categoryOf(i),
    'occurredAt': _iso(_occurredAt(i)),
    'pickup': _pickup(i),
    'stops': _stopsOf(i),
    'dropoff': _dropoff(i),
    'fare': MockMoney.json(_fareOf(i)),
    if (_isDelivery(i)) 'itemName': _items[i % _items.length]['name'],
    if (_isDelivery(i) && i % 2 == 0) 'packagePhotoUrl': _packagePhotoAsset,
  };

  static List<Map<String, dynamic>> summaries(String status) => [
    ..._recordedWith(status),
    for (var i = 0; i < _count; i++)
      if (_isCancelled(i) == (status == 'cancelled')) _summary(i),
  ];

  static String _referenceOf(int i) => '${_isDelivery(i) ? 'DL' : 'SR'}-${10000000 + (i * 7919) % 90000000}';

  static Map<String, dynamic> _livePlace(Map<String, dynamic> place) {
    final coordinates = place['coordinates'] as Map;
    final address = place['address'] as String? ?? '';
    return {
      'latitude': coordinates['lat'],
      'longitude': coordinates['lng'],
      'address': address.isEmpty ? place['name'] : address,
    };
  }

  static Map<String, dynamic> _liveDriver(int i) {
    final driver = _driverOf(i);
    final vehicle = _vehicleOf(i);
    return {
      for (final key in const ['id', 'firstName', 'lastName', 'displayName', 'photoUrl', 'rating', 'ridesCompleted'])
        key: driver[key],
      'vehicle': {
        'make': vehicle['make'],
        'model': vehicle['model'],
        'year': vehicle['year'],
        'colour': vehicle['colour'],
        'plateNumber': vehicle['plate'],
        'features': vehicle['features'],
        'featureLabels': vehicle['features'],
      },
    };
  }

  static Map<String, dynamic> _liveRide(int i) {
    final isCancelled = _isCancelled(i);
    final isDelivery = _isDelivery(i);
    final hasDriver = !isCancelled || _cancelledBy(i) != 'system';
    final category = _categoryOf(i);
    final minutes = _minutesOf(i);
    final occurredAt = _occurredAt(i);
    final requestedAt = occurredAt.subtract(Duration(minutes: minutes + 14));
    final fare = MockMoney.of(_fareOf(i)).major;
    return {
      'id': _idOf(i),
      'ref': _referenceOf(i),
      'status': isCancelled ? 'cancelled' : 'completed',
      'kind': isDelivery ? 'delivery' : 'ride',
      'rideClass': {
        'id': category,
        'code': category,
        'name': 'Sanga ${category[0].toUpperCase()}${category.substring(1)}',
      },
      'pickup': _livePlace(_pickup(i)),
      'dropoff': _livePlace(_dropoff(i)),
      'stops': [for (final stop in _stopsOf(i)) _livePlace(stop)],
      'pricingOption': 'standard',
      'tripType': 'one_way',
      'recommendedFare': fare,
      'riderFare': fare,
      'agreedFare': fare,
      'finalFare': isCancelled ? null : fare,
      'distanceKm': isCancelled ? null : _km(i),
      'durationMin': isCancelled ? null : minutes,
      'scheduledFor': null,
      'bookedFor': 'self',
      'paymentMethod': _paidWith(i, i % 2 == 1)['method'],
      'driver': hasDriver ? _liveDriver(i) : null,
      'tipAmount': 0,
      'cancelledBy': isCancelled ? _cancelledBy(i) : null,
      'cancellationReason': isCancelled ? _cancellationReasonOf(i) : null,
      'cancellationFee': isCancelled ? _cancellationFeeOf(i) : null,
      'rating': _isRated(i) ? {'stars': _stars[i % _stars.length]} : null,
      'timestamps': {
        'acceptedAt': hasDriver ? _iso(requestedAt.add(const Duration(minutes: 1))) : null,
        'arrivedAt': isCancelled ? null : _iso(requestedAt.add(const Duration(minutes: 9))),
        'startedAt': isCancelled ? null : _iso(requestedAt.add(const Duration(minutes: 12))),
        'arrivedDropoffAt': isCancelled ? null : _iso(occurredAt.subtract(const Duration(minutes: 1))),
        'completedAt': isCancelled ? null : _iso(occurredAt),
        'cancelledAt': isCancelled ? _iso(occurredAt) : null,
      },
      'createdAt': _iso(requestedAt),
      if (isDelivery) 'delivery': _deliveryOf(i),
    };
  }

  static String? _cancellationReasonOf(int i) => switch (_cancelledBy(i)) {
    'driver' => 'driver_cancelled',
    'rider' => 'rider_cancelled',
    _ => null,
  };

  static int _cancellationFeeOf(int i) => _cancelledBy(i) == 'rider' && i % 2 == 0 ? _cancellationFee : 0;

  static bool _isRated(int i) => !_isCancelled(i) && i % 3 != 1;

  static Map<String, dynamic>? liveRideOf(String id) {
    final i = _indexOf(id);
    return i == null ? null : _liveRide(i);
  }

  static List<Map<String, dynamic>> _recordedRides(String status) => [
    for (final id in _recorded.keys.toList().reversed)
      if (MockTrip.ridePayload(id) case final ride when ride['status'] == status) ride,
  ];

  static List<Map<String, dynamic>> _liveRides(String status) => switch (status) {
    'scheduled' => MockBooking.liveRides(),
    'completed' || 'cancelled' => [
      ..._recordedRides(status),
      for (var i = 0; i < _count; i++)
        if (_isCancelled(i) == (status == 'cancelled')) _liveRide(i),
    ],
    _ => const [],
  };

  static Object? _list(MockRequest request) {
    final status = request.query['status'] as String?;
    if (status != null && !_listStatuses.contains(status)) {
      throw const MockFailure(422, 'Pick a ride status we know.', code: 'invalid_status');
    }
    final page = math.max(1, int.tryParse('${request.query['page'] ?? 1}') ?? 1);
    final limit = (int.tryParse('${request.query['limit'] ?? _defaultLimit}') ?? _defaultLimit).clamp(1, _maxLimit);
    final matching = [
      for (final listed in status == null ? _listStatuses : {status}) ..._liveRides(listed),
    ];
    final start = (page - 1) * limit;
    final end = math.min(start + limit, matching.length);
    return {'rides': start >= matching.length ? const [] : matching.sublist(start, end)};
  }

  static List<Map<String, dynamic>> _receiptLines(int fare, double km, int minutes, {required bool isDelivery}) {
    var base = _roundedToFifty(fare * 0.22);
    final distance = _roundedToFifty(fare * 0.44);
    final time = _roundedToFifty(fare * 0.22);
    var service = fare - base - distance - time;
    if (service < 0) {
      base += service;
      service = 0;
    }
    return [
      {'code': 'BASE_FARE', 'label': 'Base fare', 'amount': MockMoney.of(base).major},
      {
        'code': 'DISTANCE',
        'label': 'Distance (${SangaDistance.fromKilometers(km)})',
        'amount': MockMoney.of(distance).major,
      },
      {
        'code': 'TIME',
        'label': isDelivery ? 'Handling time' : 'Time ($minutes mins)',
        'amount': MockMoney.of(time).major,
      },
      {'code': 'SERVICE_FEE', 'label': 'Service fee', 'amount': MockMoney.of(service).major},
    ];
  }

  static Map<String, dynamic> _deliveryOf(int i) {
    final item = _items[i % _items.length];
    final recipient = _recipients[i % _recipients.length];
    final hasProof = !_isCancelled(i) && i % 2 == 1;
    return {
      'tier': 'standard',
      'kind': 'package',
      'item': {
        'name': item['name'],
        'description': item['description'],
        'sizeLabel': item['size'],
        'weightLabel': item['weight'],
        'photoUrl': i % 2 == 0 ? _packagePhotoAsset : null,
      },
      'recipient': {'name': recipient['name'], 'phone': MockRegion.phone(recipient['phone']!)},
      'deliveryProof': hasProof ? {'photoUrl': _proofAsset, 'at': _iso(_occurredAt(i))} : null,
    };
  }

  static Map<String, dynamic>? receiptOf(String id) {
    final i = _indexOf(id);
    if (i == null || _isCancelled(i)) return null;
    final isDelivery = _isDelivery(i);
    final fare = _fareOf(i);
    final km = _km(i);
    final minutes = _minutesOf(i);
    final driver = _liveDriver(i);
    final vehicle = _vehicleOf(i);
    final occurredAt = _iso(_occurredAt(i));
    return {
      'rideId': id,
      'reference': _referenceOf(i),
      'kind': isDelivery ? 'delivery' : 'ride',
      'status': 'completed',
      'pickup': _livePlace(_pickup(i)),
      'dropoff': _livePlace(_dropoff(i)),
      'distanceKm': km,
      'durationMin': minutes,
      'lines': _receiptLines(fare, km, minutes, isDelivery: isDelivery),
      'adjustments': const <Map<String, dynamic>>[],
      'totalPaid': MockMoney.of(fare).major,
      'tip': 0,
      'payment': _receiptPayment(i, occurredAt),
      'completedAt': occurredAt,
      'driver': {
        'id': driver['id'],
        'name': driver['displayName'],
        'photoUrl': driver['photoUrl'],
        'ridesCompleted': driver['ridesCompleted'],
        'rating': driver['rating'],
      },
      'vehicle': {
        'display': '(${vehicle['year']} model) REG NO: ${vehicle['plate']}',
        'vehicleType': _categoryOf(i) == 'moto' ? 'bike' : 'car',
      },
    };
  }

  static Map<String, dynamic> _receiptPayment(int i, String paidAt) {
    final paidWith = _paidWith(i, i % 2 == 1);
    final method = paidWith['method'] as String;
    final last4 = paidWith['last4'] as String?;
    return {
      'method': method,
      'status': 'succeeded',
      'brand': last4 == null ? null : 'visa',
      'last4': last4,
      'display': last4 == null ? '${method[0].toUpperCase()}${method.substring(1)}' : 'Card •••• $last4',
      'paidAt': paidAt,
    };
  }

  static Map<String, dynamic> _paidWith(int i, bool isCard) {
    if (isPaidWithWallet(_idOf(i))) return {'method': 'wallet', 'last4': null};
    return {'method': isCard ? 'card' : 'cash', 'last4': isCard ? _cardLast4[i % 3] : null};
  }

  static List<Map<String, dynamic>> _blockedList() => [
    for (final entry in _blockedDrivers.entries) {'driverId': entry.key, 'blockedAt': _iso(entry.value)},
  ];

  static Object? _block(MockRequest request) {
    final id = request.body['driverId'] as String? ?? '';
    final isKnown = MockData.driverOffers.any((offer) => (offer['driver'] as Map)['id'] == id);
    if (!isKnown) throw const MockFailure(404, 'We can’t find that driver.', code: 'driver_not_found');
    _blockedDrivers.putIfAbsent(id, DateTime.now);
    return {'driverId': id, 'blocked': true, 'serverTime': _iso(DateTime.now())};
  }

  static Object? _unblock(MockRequest request) {
    final id = request.params['driverId']!;
    _blockedDrivers.remove(id);
    return {'driverId': id, 'blocked': false, 'serverTime': _iso(DateTime.now())};
  }
}
