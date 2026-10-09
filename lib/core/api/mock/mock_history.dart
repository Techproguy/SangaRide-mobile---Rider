import 'dart:math' as math;

import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

abstract final class MockHistory {
  static final List<MockRoute> routes = [
    MockRoute.get(HistoryEndpoints.rides, _list),
    MockRoute.get(HistoryEndpoints.rideById, _detail),
    MockRoute.post(HistoryEndpoints.blockDriver, (request) => _setBlocked(request, true)),
    MockRoute.delete(HistoryEndpoints.blockDriver, (request) => _setBlocked(request, false)),
  ];

  static const int _count = 30;
  static const int _defaultPageSize = 10;
  static const int _maxPageSize = 50;
  static const int _minutesBetweenTrips = 1290;
  static const int _cancellationFee = 300;
  static const String _proofAsset = 'assets/images/service_delivery.webp';

  static final DateTime _anchor = DateTime.now();
  static final Set<String> _blockedDrivers = {};
  static final Map<String, Map<String, dynamic> Function()> _recorded = {};

  static void recordTrip(String id, Map<String, dynamic> Function() detailOf) => _recorded[id] = detailOf;

  static List<Map<String, dynamic>> _recordedWith(String status) => [
    for (final detailOf in _recorded.values.toList().reversed)
      if (detailOf() case final detail when detail['status'] == status) detail,
  ];

  static const List<Map<String, dynamic>> _stops = [
    {
      'place_id': 'mock_cr_ikeja',
      'name': 'Chicken Republic',
      'address': 'Allen Avenue, Ikeja, Lagos',
      'coordinates': {'lat': 6.6018, 'lng': 3.3515},
    },
    {
      'place_id': 'mock_cr_idumota',
      'name': 'Chicken Republic',
      'address': 'Nnamdi Azikiwe Street, Idumota, Lagos',
      'coordinates': {'lat': 6.4601, 'lng': 3.3895},
    },
    {
      'place_id': 'mock_palms',
      'name': 'The Palms Mall',
      'address': 'Lekki Phase 1, Lagos',
      'coordinates': {'lat': 6.4352, 'lng': 3.4515},
    },
    {
      'place_id': 'mock_yabatech',
      'name': 'Yaba College of Technology',
      'address': 'Herbert Macaulay Way, Yaba, Lagos',
      'coordinates': {'lat': 6.5191, 'lng': 3.3741},
    },
    {
      'place_id': 'mock_icm',
      'name': 'Ikeja City Mall',
      'address': 'Obafemi Awolowo Way, Ikeja, Lagos',
      'coordinates': {'lat': 6.6142, 'lng': 3.3576},
    },
    {
      'place_id': 'mock_eko',
      'name': 'Eko Hotel and Suites',
      'address': 'Adetokunbo Ademola Street, Victoria Island, Lagos',
      'coordinates': {'lat': 6.4262, 'lng': 3.4290},
    },
    {
      'place_id': 'mock_unilag',
      'name': 'University of Lagos',
      'address': 'Akoka, Yaba, Lagos',
      'coordinates': {'lat': 6.5158, 'lng': 3.3966},
    },
    {
      'place_id': 'mock_airport',
      'name': 'Murtala Muhammed International Airport',
      'address': 'Ikeja, Lagos',
      'coordinates': {'lat': 6.5774, 'lng': 3.3212},
    },
    {
      'place_id': 'mock_home',
      'name': '12 Ajegule Street',
      'address': '12 Ajegule Street, Ikorodu, Lagos',
      'coordinates': {'lat': 6.6194, 'lng': 3.5105},
    },
    {
      'place_id': 'mock_work',
      'name': 'Akeredolu Building',
      'address': 'Akeredolu Building, Agege, Lagos',
      'coordinates': {'lat': 6.6180, 'lng': 3.3209},
    },
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
    {'name': 'Oladimeji Samuel', 'phone': '+2348015901779'},
    {'name': 'Ajani Toluwanimi', 'phone': '+2348054308337'},
    {'name': 'Lawal James Israel', 'phone': '+2348146234260'},
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

  static Map<String, dynamic> _stop(int index) => Map<String, dynamic>.of(_stops[index % _stops.length]);

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
    final driver = drivers[i % drivers.length];
    return {...driver, 'blocked': _blockedDrivers.contains(driver['id'])};
  }

  static Map<String, dynamic> _vehicleOf(int i) => {
    ..._vehicles[i % _vehicles.length],
    'features': const ['Air conditioned'],
  };

  static Map<String, dynamic> _summary(int i) => {
    'id': _idOf(i),
    'kind': _isDelivery(i) ? 'delivery' : 'ride',
    'status': _isCancelled(i) ? 'cancelled' : 'completed',
    'category': _categoryOf(i),
    'occurredAt': _iso(_occurredAt(i)),
    'pickup': _pickup(i),
    'stops': _stopsOf(i),
    'dropoff': _dropoff(i),
    'fare': _fareOf(i),
    if (_isDelivery(i)) 'itemName': _items[i % _items.length]['name'],
  };

  static List<Map<String, dynamic>> summaries(String status) => [
    ..._recordedWith(status),
    for (var i = 0; i < _count; i++)
      if (_isCancelled(i) == (status == 'cancelled')) _summary(i),
  ];

  static Object? _list(MockRequest request) {
    final status = request.query['status'] as String?;
    if (status != 'completed' && status != 'cancelled') {
      throw const MockFailure(422, 'Pick completed or cancelled.', code: 'invalid_status');
    }
    final page = math.max(1, int.tryParse('${request.query['page'] ?? 1}') ?? 1);
    final pageSize = (int.tryParse('${request.query['pageSize'] ?? _defaultPageSize}') ?? _defaultPageSize).clamp(
      1,
      _maxPageSize,
    );
    final matching = summaries(status!);
    final start = (page - 1) * pageSize;
    final end = math.min(start + pageSize, matching.length);
    return {
      'items': start >= matching.length ? const [] : matching.sublist(start, end),
      'page': page,
      'hasMore': end < matching.length,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static List<Map<String, dynamic>> _lines(int fare, double km, int minutes, {required bool isDelivery}) {
    var base = _roundedToFifty(fare * 0.22);
    final distance = _roundedToFifty(fare * 0.44);
    final time = _roundedToFifty(fare * 0.22);
    var service = fare - base - distance - time;
    if (service < 0) {
      base += service;
      service = 0;
    }
    return [
      {'key': 'base_fare', 'label': 'Base fare', 'amount': base},
      {'key': 'distance', 'label': 'Distance ($km km)', 'amount': distance},
      {'key': 'time', 'label': isDelivery ? 'Handling time' : 'Time ($minutes mins)', 'amount': time},
      {'key': 'service_fee', 'label': 'Service fee', 'amount': service},
    ];
  }

  static Map<String, dynamic> _event(String type, DateTime at) => {'type': type, 'at': _iso(at)};

  static List<Map<String, dynamic>> _completedEvents(int i, DateTime requestedAt, DateTime occurredAt) {
    final isDelivery = _isDelivery(i);
    return [
      _event('driver_accepted', requestedAt.add(const Duration(minutes: 1))),
      _event('driver_arrived', requestedAt.add(const Duration(minutes: 9))),
      _event(isDelivery ? 'package_picked_up' : 'trip_started', requestedAt.add(const Duration(minutes: 12))),
      _event('arrived_dropoff', occurredAt.subtract(const Duration(minutes: 1))),
      _event(isDelivery ? 'package_delivered' : 'trip_completed', occurredAt),
    ];
  }

  static List<Map<String, dynamic>> _cancelledEvents(int i, DateTime requestedAt, DateTime occurredAt) => [
    if (_cancelledBy(i) != 'system') _event('driver_accepted', requestedAt.add(const Duration(minutes: 1))),
    _event(_isDelivery(i) ? 'delivery_cancelled' : 'ride_cancelled', occurredAt),
  ];

  static const Map<String, String> _cancelReasons = {
    'driver': 'Driver did not arrive on time to the pick up point',
    'rider': 'You changed your plans',
    'system': 'We couldn’t find a driver close enough to you',
  };

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
        'photoUrl': null,
      },
      'recipient': {'name': recipient['name'], 'phone': recipient['phone']},
      'deliveryProof': hasProof ? {'photoUrl': _proofAsset, 'at': _iso(_occurredAt(i))} : null,
    };
  }

  static Object? _detail(MockRequest request) {
    final recorded = _recorded[request.params['id']];
    if (recorded != null) return {...recorded(), 'serverTime': _iso(DateTime.now())};
    final i = _indexOf(request.params['id']!);
    if (i == null) throw const MockFailure(404, 'We can’t find that trip.', code: 'not_found');
    final isCancelled = _isCancelled(i);
    final isDelivery = _isDelivery(i);
    final occurredAt = _occurredAt(i);
    final minutes = _minutesOf(i);
    final requestedAt = occurredAt.subtract(Duration(minutes: minutes + 14));
    final fare = _fareOf(i);
    final km = _km(i);
    final cancelledBy = _cancelledBy(i);
    final hasDriver = !isCancelled || cancelledBy != 'system';
    final isRated = !isCancelled && i % 3 != 1;
    final counter = !isCancelled && !isDelivery && i % 5 == 2;
    final isCard = i % 2 == 1;
    return {
      ..._summary(i),
      'reference': '${isDelivery ? 'DL' : 'SR'}-${10000000 + (i * 7919) % 90000000}',
      'requestedAt': _iso(requestedAt),
      'counterOffer': counter ? fare : null,
      'distanceKm': isCancelled ? null : km,
      'durationMinutes': isCancelled ? null : minutes,
      'lines': isCancelled ? const [] : _lines(fare, km, minutes, isDelivery: isDelivery),
      'paidWith': isCancelled ? null : _paidWith(i, isCard),
      'driver': hasDriver ? _driverOf(i) : null,
      'vehicle': hasDriver ? _vehicleOf(i) : null,
      'events': isCancelled
          ? _cancelledEvents(i, requestedAt, occurredAt)
          : _completedEvents(i, requestedAt, occurredAt),
      'rating': isRated ? {'stars': _stars[i % _stars.length]} : null,
      'cancellation': isCancelled
          ? {
              'by': cancelledBy,
              'reason': _cancelReasons[cancelledBy],
              'fee': cancelledBy == 'rider' && i % 2 == 0 ? _cancellationFee : 0,
            }
          : null,
      'delivery': isDelivery ? _deliveryOf(i) : null,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Map<String, dynamic> _paidWith(int i, bool isCard) {
    if (isPaidWithWallet(_idOf(i))) return {'method': 'wallet', 'last4': null};
    return {'method': isCard ? 'card' : 'cash', 'last4': isCard ? _cardLast4[i % 3] : null};
  }

  static Object? _setBlocked(MockRequest request, bool isBlocked) {
    final id = request.params['id']!;
    final isKnown = MockData.driverOffers.any((offer) => (offer['driver'] as Map)['id'] == id);
    if (!isKnown) throw const MockFailure(404, 'We can’t find that driver.', code: 'driver_not_found');
    if (isBlocked) {
      _blockedDrivers.add(id);
    } else {
      _blockedDrivers.remove(id);
    }
    return {'driverId': id, 'blocked': isBlocked, 'serverTime': _iso(DateTime.now())};
  }
}
