import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_changes.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';

abstract final class MockTrip {
  static final List<MockRoute> routes = [
    MockRoute.get(MockEndpoints.activeTrip, (_) => _active()),
    MockRoute.get(MockEndpoints.liveTrip, (request) => _payload(request.params['id']!)),
    MockRoute.post(MockEndpoints.liveTripConfirmDetails, _confirmDetails),
    MockRoute.post(MockEndpoints.liveTripPinRefresh, _refreshPin),
    MockRoute.post(MockEndpoints.liveTripReport, _report),
    MockRoute.post(MockEndpoints.liveTripComplete, _complete),
    MockRoute.post(MockEndpoints.liveTripCall, (_) => {'maskedNumber': _maskedNumber}),
    MockRoute.get(MockEndpoints.liveTripMessages, _messages),
    MockRoute.post(MockEndpoints.liveTripMessages, _sendMessage),
    MockRoute.get(MockEndpoints.liveTripEvents, (request) => {'events': _events(request.params['id']!)}),
    ...MockTripChanges.routes,
  ];

  static final Map<String, Map<String, dynamic>> requests = {};

  static final Map<String, DateTime> _detailsConfirmedAt = {};
  static final Map<String, DateTime> _completedAt = {};
  static final Map<String, DateTime> _cancelledAt = {};
  static final Map<String, String> _cancelReasons = {};
  static final Map<String, DateTime> _messagesReadAt = {};
  static final Map<String, List<Map<String, dynamic>>> _riderMessages = {};
  static final Set<String> _failedOnce = {};
  static final Map<String, int> _pinIndex = {};
  static final Map<String, _RideLeg> _legs = {};
  static final Map<String, String> _cancelledBy = {};

  static const Duration _arrivalAfter = Duration(seconds: 15);
  static const Duration _pinVerifiedAfter = Duration(seconds: 6);
  static const Duration _rideDuration = Duration(seconds: 20);
  static const Duration _legExtra = Duration(seconds: 8);
  static const Duration _pinWindow = Duration(minutes: 5);

  static const List<String> _pinCodes = ['5428', '7391', '2064', '8815'];
  static const String _maskedNumber = '+2342019990001';
  static const double _routeDetour = 1.3;

  static const Map<String, dynamic> _fallbackPickup = {
    'name': 'Ikeja City Mall',
    'address': 'Obafemi Awolowo Way, Ikeja',
    'lat': 6.6145,
    'lng': 3.3569,
  };
  static const Map<String, dynamic> _fallbackDropoff = {
    'name': 'Lekki Phase 1',
    'address': 'Admiralty Way, Lekki',
    'lat': 6.4478,
    'lng': 3.4723,
  };
  static const double _averageSpeedKmh = 25;

  static const List<(Duration, String, String)> _driverMessages = [
    (Duration(seconds: 3), 'msg_driver_1', 'Hello, I’m on my way to your pickup.'),
    (Duration(seconds: 10), 'msg_driver_2', 'I’m in {vehicle}. See you soon!'),
  ];

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static void open({
    required String tripId,
    required Map<String, dynamic> request,
    required Map<String, dynamic> driverCard,
    required int proposedFare,
    required int? counterOffer,
    required num etaMinutes,
  }) {
    final now = DateTime.now();
    final pickup = _place(request['pickup'], _fallbackPickup);
    final stops = [for (final stop in request['stops'] as List? ?? const []) _place(stop, _fallbackPickup)];
    final dropoff = _place(request['dropoff'], _fallbackDropoff);
    final category = (request['optionId'] as String?) ?? 'go';
    final points = [pickup, ...stops, dropoff];
    var routeKm = 0.0;
    for (var i = 1; i < points.length; i++) {
      routeKm += _distanceKm(points[i - 1], points[i]);
    }
    final distanceKm = double.parse((routeKm * _routeDetour).toStringAsFixed(1));
    MockTripState.trips[tripId] = {
      'id': tripId,
      'createdAt': _iso(now),
      'category': category,
      'driver': {...driverCard}
        ..remove('vehicle')
        ..remove('distanceAwayKm'),
      'vehicle': {...(driverCard['vehicle'] as Map<String, dynamic>), 'category': category},
      'pickup': pickup,
      'stops': stops,
      'dropoff': dropoff,
      'fare': counterOffer ?? proposedFare,
      'counterOffer': counterOffer,
      'distanceKm': distanceKm,
      'durationMinutes': math.max(5, (distanceKm / _averageSpeedKmh * 60).round()),
      'pin': _pinCodes.first,
      'pinExpiresAt': _iso(now.add(_pinWindow)),
      'etaMinutes': etaMinutes,
      'driverStart': {'lat': (pickup['lat'] as num) + 0.012, 'lng': (pickup['lng'] as num) - 0.01},
    };
    _pinIndex[tripId] = 0;
  }

  static Map<String, dynamic> _place(Object? json, Map<String, dynamic> fallback) {
    final place = json is Map ? Map<String, dynamic>.from(json) : fallback;
    final coordinates = place['coordinates'];
    final lat = coordinates is Map ? coordinates['lat'] : place['lat'];
    final lng = coordinates is Map ? coordinates['lng'] : place['lng'];
    return {
      'name': place['name'] ?? fallback['name'],
      'address': place['address'] ?? '',
      'lat': lat ?? fallback['lat'],
      'lng': lng ?? fallback['lng'],
    };
  }

  static Map<String, dynamic> _apiPlace(Map<String, dynamic> place) => {
    'name': place['name'],
    'address': place['address'],
    'coordinates': {'lat': place['lat'], 'lng': place['lng']},
  };

  static const double routeDetour = _routeDetour;

  static Map<String, dynamic> stored(String id) => _stored(id);

  static String statusOf(String id) => _status(id, DateTime.now());

  static Map<String, dynamic> payload(String id) => _payload(id);

  static DateTime createdAt(String id) => _createdAt(_stored(id));

  static Map<String, dynamic> placeOf(Object? json) => _place(json, _fallbackPickup);

  static double distanceBetween(Map a, Map b) => _distanceKm(a, b);

  static bool isCancelled(String id) => _cancelledAt.containsKey(id);

  static String? cancelledBy(String id) => _cancelledBy[id];

  static void cancel(String id, {required String reason, required String by}) {
    _cancelledAt[id] = DateTime.now();
    _cancelReasons[id] = reason;
    _cancelledBy[id] = by;
  }

  static double travelledFraction(String id) {
    final leg = _legOf(id);
    return leg == null ? 0 : _legProgress(leg, DateTime.now());
  }

  static Map<String, dynamic> routeStart(String id) {
    final trip = _stored(id);
    final leg = _legOf(id);
    if (leg == null || _status(id, DateTime.now()) != 'in_progress') return trip['pickup'] as Map<String, dynamic>;
    return _legPosition(leg, DateTime.now());
  }

  static List<Map<String, dynamic>> pendingStops(String id) {
    final trip = _stored(id);
    final reached = _reachedStops(id, DateTime.now());
    return [for (final stop in (trip['stops'] as List).skip(reached)) stop as Map<String, dynamic>];
  }

  static void addStops(String id, List<Map<String, dynamic>> places) {
    final trip = _stored(id);
    final now = DateTime.now();
    final leg = _legOf(id);
    if (leg != null) {
      final reached = leg.reachedBefore + _reachedNow(leg, now);
      _legs[id] = _RideLeg(
        startedAt: now,
        endAt: leg.endAt.add(_legExtra * places.length),
        from: _legPosition(leg, now),
        targets: [...pendingStops(id), ...places, trip['dropoff'] as Map<String, dynamic>],
        reachedBefore: reached,
      );
    }
    (trip['stops'] as List).addAll(places);
  }

  static Map<String, dynamic> _stored(String id) {
    final trip = MockTripState.trips[id];
    if (trip == null) throw const MockFailure(404, 'We can’t find that trip.');
    return trip;
  }

  static DateTime _createdAt(Map<String, dynamic> trip) => DateTime.parse(trip['createdAt'] as String);

  static String _status(String id, DateTime now) {
    final trip = _stored(id);
    if (_cancelledAt.containsKey(id)) return 'cancelled';
    if (_completedAt.containsKey(id)) return 'completed';
    final leg = _legOf(id);
    if (leg != null) return now.isBefore(leg.endAt) ? 'in_progress' : 'arrived_dropoff';
    final confirmedAt = _detailsConfirmedAt[id];
    if (confirmedAt != null && now.difference(confirmedAt) >= _pinVerifiedAfter) return 'pin_verified';
    return now.difference(_createdAt(trip)) >= _arrivalAfter ? 'driver_arrived' : 'driver_en_route';
  }

  static Map<String, dynamic> _payload(String id) {
    final trip = _stored(id);
    final now = DateTime.now();
    final status = _status(id, now);
    final showsPin = status == 'driver_arrived' && _detailsConfirmedAt.containsKey(id);
    final position = _driverPosition(trip, status, now);
    return {
      'id': id,
      'status': status,
      'serverTime': _iso(now),
      'rideType': trip['category'],
      'driver': trip['driver'],
      'vehicle': trip['vehicle'],
      'pickup': _apiPlace(trip['pickup'] as Map<String, dynamic>),
      'stops': _apiStops(id, now),
      'dropoff': _apiPlace(trip['dropoff'] as Map<String, dynamic>),
      'fare': {'total': trip['fare'], 'counterOffer': trip['counterOffer'], 'currency': 'NGN'},
      if (showsPin) 'pin': trip['pin'],
      if (showsPin) 'pinExpiresAt': trip['pinExpiresAt'],
      if (status == 'driver_en_route') 'etaAt': _iso(now.add(_travelTime(_distanceRemaining(trip, status, position)))),
      if (status == 'in_progress') 'etaAt': _iso(_legOf(id)!.endAt),
      'distanceRemainingKm': _distanceRemaining(trip, status, position),
      'driverPosition': position,
      'unreadMessages': _unread(id, now),
      'events': _events(id),
      'cancellationReason': ?_cancelReasons[id],
      'airport': ?MockAirport.tripBlock(id),
    };
  }

  static Map<String, dynamic>? _active() {
    for (final id in MockTripState.trips.keys.toList().reversed) {
      final status = _status(id, DateTime.now());
      if (status != 'completed' && status != 'cancelled') return _payload(id);
    }
    return null;
  }

  static Object? _confirmDetails(MockRequest request) {
    final id = request.params['id']!;
    final status = _status(id, DateTime.now());
    if (status == 'driver_en_route') throw const MockFailure(409, 'Your driver is still on the way.');
    if (status != 'driver_arrived') throw const MockFailure(409, 'This trip has already moved on.');
    if (!_detailsConfirmedAt.containsKey(id)) {
      final now = DateTime.now();
      _detailsConfirmedAt[id] = now;
      _stored(id)['pinExpiresAt'] = _iso(now.add(_pinWindow));
    }
    return _payload(id);
  }

  static Object? _refreshPin(MockRequest request) {
    final id = request.params['id']!;
    if (_status(id, DateTime.now()) != 'driver_arrived' || !_detailsConfirmedAt.containsKey(id)) {
      throw const MockFailure(409, 'A new PIN isn’t available right now.');
    }
    final next = ((_pinIndex[id] ?? 0) + 1) % _pinCodes.length;
    _pinIndex[id] = next;
    _stored(id)
      ..['pin'] = _pinCodes[next]
      ..['pinExpiresAt'] = _iso(DateTime.now().add(_pinWindow));
    return _payload(id);
  }

  static Object? _report(MockRequest request) {
    final id = request.params['id']!;
    final reasons = request.body['reasons'];
    if (reasons is! List || reasons.isEmpty) throw const MockFailure(422, 'Pick at least one reason.');
    if (_status(id, DateTime.now()) != 'driver_arrived') {
      throw const MockFailure(409, 'This trip has already moved on.');
    }
    cancel(id, reason: 'driver_mismatch', by: 'rider');
    return _payload(id);
  }

  static Object? _complete(MockRequest request) {
    final id = request.params['id']!;
    if (_status(id, DateTime.now()) != 'arrived_dropoff') {
      throw const MockFailure(409, 'You can complete the ride once you’ve arrived.');
    }
    _completedAt[id] = DateTime.now();
    return _payload(id);
  }

  static Map<String, dynamic> _driverPosition(Map<String, dynamic> trip, String status, DateTime now) {
    final start = trip['driverStart'] as Map<String, dynamic>;
    final pickup = trip['pickup'] as Map<String, dynamic>;
    final dropoff = trip['dropoff'] as Map<String, dynamic>;
    final id = trip['id'] as String;
    switch (status) {
      case 'driver_en_route':
        final progress = _progress(now.difference(_createdAt(trip)), _arrivalAfter);
        return _position(_lerp(start, pickup, progress), _bearing(start, pickup));
      case 'in_progress':
        return _legPosition(_legOf(id)!, now);
      case 'arrived_dropoff' || 'completed':
        return _position(dropoff, _bearing(pickup, dropoff));
      default:
        return _position(pickup, _bearing(start, pickup));
    }
  }

  static _RideLeg? _legOf(String id) {
    final explicit = _legs[id];
    if (explicit != null) return explicit;
    final paidAt = MockTripState.paidAt[id];
    if (paidAt == null) return null;
    final trip = _stored(id);
    final stops = (trip['stops'] as List).cast<Map<String, dynamic>>();
    return _RideLeg(
      startedAt: paidAt,
      endAt: paidAt.add(_rideDuration + _legExtra * stops.length),
      from: trip['pickup'] as Map<String, dynamic>,
      targets: [...stops, trip['dropoff'] as Map<String, dynamic>],
      reachedBefore: 0,
    );
  }

  static double _legProgress(_RideLeg leg, DateTime now) =>
      _progress(now.difference(leg.startedAt), leg.endAt.difference(leg.startedAt));

  static List<double> _cumulativeKm(List<Map<String, dynamic>> points) {
    final cumulative = [0.0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + _distanceKm(points[i - 1], points[i]));
    }
    return cumulative;
  }

  static Map<String, dynamic> _legPosition(_RideLeg leg, DateTime now) {
    final points = [leg.from, ...leg.targets];
    final cumulative = _cumulativeKm(points);
    final travelled = cumulative.last * _legProgress(leg, now);
    var index = 1;
    while (index < points.length - 1 && cumulative[index] < travelled) {
      index++;
    }
    final segment = cumulative[index] - cumulative[index - 1];
    final t = segment == 0 ? 1.0 : ((travelled - cumulative[index - 1]) / segment).clamp(0.0, 1.0);
    return _position(_lerp(points[index - 1], points[index], t), _bearing(points[index - 1], points[index]));
  }

  static int _reachedNow(_RideLeg leg, DateTime now) {
    final points = [leg.from, ...leg.targets];
    final cumulative = _cumulativeKm(points);
    final progress = _legProgress(leg, now);
    var reached = 0;
    for (var i = 1; i < points.length - 1; i++) {
      final fraction = cumulative.last == 0 ? 0.0 : cumulative[i] / cumulative.last;
      if (progress <= 0 || progress < fraction) break;
      reached++;
    }
    return reached;
  }

  static int _reachedStops(String id, DateTime now) {
    final leg = _legOf(id);
    return leg == null ? 0 : leg.reachedBefore + _reachedNow(leg, now);
  }

  static List<Map<String, dynamic>> _apiStops(String id, DateTime now) {
    final reached = _reachedStops(id, now);
    return [
      for (final (index, stop) in (_stored(id)['stops'] as List).indexed)
        {..._apiPlace(stop as Map<String, dynamic>), 'status': index < reached ? 'reached' : 'pending'},
    ];
  }

  static const double _cityMinutesPerKm = 2.4;

  static Duration _travelTime(double? km) =>
      Duration(seconds: ((km ?? 0) * _cityMinutesPerKm * 60).round().clamp(60, 7200));

  static double _progress(Duration elapsed, Duration total) =>
      (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

  static Map<String, dynamic> _position(Map<String, dynamic> point, double heading) => {
    'lat': point['lat'],
    'lng': point['lng'],
    'heading': heading,
  };

  static Map<String, dynamic> _lerp(Map<String, dynamic> from, Map<String, dynamic> to, double t) => {
    'lat': (from['lat'] as num) + ((to['lat'] as num) - (from['lat'] as num)) * t,
    'lng': (from['lng'] as num) + ((to['lng'] as num) - (from['lng'] as num)) * t,
  };

  static double _bearing(Map<String, dynamic> from, Map<String, dynamic> to) {
    double radians(num degrees) => degrees * math.pi / 180;
    final dLng = radians((to['lng'] as num) - (from['lng'] as num));
    final fromLat = radians(from['lat'] as num);
    final toLat = radians(to['lat'] as num);
    final y = math.sin(dLng) * math.cos(toLat);
    final x = math.cos(fromLat) * math.sin(toLat) - math.sin(fromLat) * math.cos(toLat) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double? _distanceRemaining(Map<String, dynamic> trip, String status, Map<String, dynamic> position) {
    final target = switch (status) {
      'driver_en_route' => trip['pickup'],
      'in_progress' => trip['dropoff'],
      _ => null,
    };
    if (target == null) return null;
    return double.parse((_distanceKm(position, target as Map<String, dynamic>) * _routeDetour).toStringAsFixed(1));
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

  static List<Map<String, dynamic>> _events(String id) {
    final trip = _stored(id);
    final now = DateTime.now();
    final created = _createdAt(trip);
    final confirmedAt = _detailsConfirmedAt[id];
    final paidAt = MockTripState.paidAt[id];
    final candidates = <(String, DateTime?)>[
      ('driver_accepted', created),
      ('driver_arrived', created.add(_arrivalAfter)),
      ('details_confirmed', confirmedAt),
      ('pin_verified', confirmedAt?.add(_pinVerifiedAfter)),
      ('trip_started', paidAt),
      ('arrived_dropoff', _legOf(id)?.endAt),
      ('trip_completed', _completedAt[id]),
      ('trip_cancelled', _cancelledAt[id]),
    ];
    return [
      for (final (type, at) in candidates)
        if (at != null && !at.isAfter(now)) {'type': type, 'at': _iso(at)},
    ];
  }

  static List<Map<String, dynamic>> _driverMessagesOf(String id) {
    final trip = _stored(id);
    final vehicle = trip['vehicle'] as Map<String, dynamic>;
    final description = 'a ${vehicle['colour']} ${vehicle['make']} ${vehicle['model']}';
    final created = _createdAt(trip);
    final now = DateTime.now();
    return [
      for (final (offset, messageId, text) in _driverMessages)
        if (!created.add(offset).isAfter(now))
          {
            'id': messageId,
            'clientId': null,
            'senderRole': 'driver',
            'body': text.replaceFirst('{vehicle}', description),
            'createdAt': _iso(created.add(offset)),
            'status': 'sent',
          },
    ];
  }

  static List<Map<String, dynamic>> _allMessages(String id) {
    final all = [..._driverMessagesOf(id), ...?_riderMessages[id]];
    all.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));
    return all;
  }

  static int _unread(String id, DateTime now) {
    final readAt = _messagesReadAt[id];
    return _driverMessagesOf(id).where((message) {
      final sentAt = DateTime.parse(message['createdAt'] as String);
      return readAt == null || sentAt.isAfter(readAt);
    }).length;
  }

  static Object? _messages(MockRequest request) {
    final id = request.params['id']!;
    _stored(id);
    _messagesReadAt[id] = DateTime.now();
    return {'messages': _allMessages(id)};
  }

  static Object? _sendMessage(MockRequest request) {
    final id = request.params['id']!;
    _stored(id);
    final body = (request.body['body'] as String?)?.trim() ?? '';
    final clientId = request.body['clientId'] as String?;
    if (body.isEmpty) throw const MockFailure(422, 'Write a message first.');
    if (body.contains('#fail') && clientId != null && _failedOnce.add(clientId)) {
      throw const MockFailure(503, 'Message not sent.');
    }
    final now = DateTime.now();
    if (body.contains('#drivercancel') && !_cancelledAt.containsKey(id) && _status(id, now) != 'completed') {
      cancel(id, reason: 'driver_cancelled', by: 'driver');
    }
    final message = {
      'id': 'msg_rider_${(_riderMessages[id]?.length ?? 0) + 1}',
      'clientId': clientId,
      'senderRole': 'rider',
      'body': body,
      'createdAt': _iso(now),
      'status': 'sent',
    };
    _riderMessages.putIfAbsent(id, () => []).add(message);
    return message;
  }
}

class _RideLeg {
  const _RideLeg({
    required this.startedAt,
    required this.endAt,
    required this.from,
    required this.targets,
    required this.reachedBefore,
  });

  final DateTime startedAt;
  final DateTime endAt;
  final Map<String, dynamic> from;
  final List<Map<String, dynamic>> targets;
  final int reachedBefore;
}
