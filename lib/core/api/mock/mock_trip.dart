import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery_live.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_changes.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_wrapup.dart';

abstract final class MockTrip {
  static final List<MockRoute> routes = [
    MockRoute.get(AppEndpoints.activeTrip, (_) => _active()),
    MockRoute.post(AppEndpoints.liveTripConfirmDetails, _confirmDetails),
    MockRoute.post(AppEndpoints.liveTripPinRefresh, _revealPin),
    MockRoute.post(AppEndpoints.liveTripReport, _report),
    MockRoute.post(AppEndpoints.liveTripCall, (_) => {'maskedNumber': MockRegion.maskedCallNumber}),
    MockRoute.post(AppEndpoints.tripShare, _share),
    MockRoute.get(AppEndpoints.liveTripMessages, _messages),
    MockRoute.post(AppEndpoints.liveTripMessages, _sendMessage),
    MockRoute.post('${AppEndpoints.liveTripMessages}/read', _markMessagesRead),
    ...MockTripChanges.routes,
    ...MockDeliveryLive.routes,
  ];

  static final Map<String, Map<String, dynamic>> requests = {};

  static final Map<String, DateTime> _detailsConfirmedAt = {};
  static final Map<String, DateTime> _pinRevealedAt = {};
  static final Map<String, DateTime> _completedAt = {};
  static final Map<String, DateTime> _cancelledAt = {};
  static final Map<String, String> _cancelReasons = {};
  static final Map<String, DateTime> _messagesReadAt = {};
  static final Map<String, List<Map<String, dynamic>>> _riderMessages = {};
  static final Set<String> _failedOnce = {};
  static final Map<String, int> _pinIndex = {};
  static final Map<String, _RideLeg> _legs = {};
  static final Map<String, _RideLeg> _returnLegs = {};
  static final Map<String, String> _cancelledBy = {};

  static const Duration _arrivalAfter = Duration(seconds: 15);
  static const Duration _pinVerifiedAfter = Duration(seconds: 6);
  static const Duration _rideDuration = Duration(seconds: 20);
  static const Duration _legExtra = Duration(seconds: 8);
  static const Duration _returnDuration = Duration(seconds: 30);
  static const Duration _driverCompletesAfter = Duration(seconds: 4);
  static const Duration _pinWindow = Duration(minutes: 5);

  static const List<String> _pinCodes = ['5428', '7391', '2064', '8815'];
  static const double _routeDetour = 1.3;

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
    final pickup = _place(request['pickup'], MockRegion.fallbackPickup);
    final stops = [for (final stop in request['stops'] as List? ?? const []) _place(stop, MockRegion.fallbackPickup)];
    final dropoff = _place(request['dropoff'], MockRegion.fallbackDropoff);
    final category = (request['optionId'] as String?) ?? 'go';
    final points = [pickup, ...stops, dropoff];
    var routeKm = 0.0;
    for (var i = 1; i < points.length; i++) {
      routeKm += _distanceKm(points[i - 1], points[i]);
    }
    final distanceKm = double.parse((routeKm * _routeDetour).toStringAsFixed(1));
    final scheduledAt = MockAirport.pickupAtOf(tripId) ?? DateTime.tryParse('${request['scheduledAt']}');
    MockTripState.trips[tripId] = {
      'id': tripId,
      'createdAt': _iso(now),
      'category': category,
      'scheduledAt': scheduledAt == null ? null : _iso(scheduledAt),
      'rideFor': request['rideFor'],
      'driver': {...driverCard}
        ..remove('vehicle')
        ..remove('distanceAwayKm'),
      'vehicle': {...(driverCard['vehicle'] as Map<String, dynamic>), 'category': category},
      'pickup': pickup,
      'stops': stops,
      'dropoff': dropoff,
      'fare': counterOffer ?? proposedFare,
      'riderFare': proposedFare,
      'counterOffer': counterOffer,
      'distanceKm': distanceKm,
      'durationMinutes': math.max(5, (distanceKm / _averageSpeedKmh * 60).round()),
      'pin': _pinCodes.first,
      'pinExpiresAt': _iso(now.add(_pinWindow)),
      'etaMinutes': etaMinutes,
      'driverStart': {'lat': (pickup['lat'] as num) + 0.012, 'lng': (pickup['lng'] as num) - 0.01},
    };
    _pinIndex[tripId] = 0;
    MockDeliveryLive.attach(tripId, request);
    MockDeliveryLive.bind(
      MockDeliveryLink(
        clockOf: _deliveryClock,
        payloadOf: _ridePayload,
        cancel: (id, {required reason}) => cancel(id, reason: reason, by: 'system'),
        reassign: _reassignDriver,
        startReturn: _startReturn,
      ),
    );
  }

  static MockDeliveryClock _deliveryClock(String id) {
    final trip = _stored(id);
    final now = DateTime.now();
    final created = _createdAt(trip);
    final back = _returnLegOf(id);
    return MockDeliveryClock(
      now: now,
      status: _status(id, now),
      createdAt: created,
      arrivedAt: created.add(_arrivalAfter),
      pinVerifiedAt: _pinVerifiedAt(id),
      arrivedDropoffAt: _legOf(id)?.endAt,
      completedAt: _completedAt[id],
      returnStartedAt: back?.startedAt,
      returnedAt: back?.endAt,
      dropoff: trip['dropoff'] as Map<String, dynamic>,
    );
  }

  static void _startReturn(String id) {
    final trip = _stored(id);
    final now = DateTime.now();
    _returnLegs[id] = _RideLeg(
      startedAt: now,
      endAt: now.add(_returnDuration),
      from: _driverPosition(trip, _status(id, now), now),
      targets: [trip['pickup'] as Map<String, dynamic>],
      reachedBefore: 0,
    );
  }

  static _RideLeg? _returnLegOf(String id) {
    final explicit = _returnLegs[id];
    if (explicit != null) return explicit;
    final arrivedAt = _legOf(id)?.endAt;
    if (arrivedAt == null || !MockDeliveryLive.returnsFromDropoff(id)) return null;
    final trip = _stored(id);
    final startedAt = arrivedAt.add(MockDeliveryLive.returnAfterArrival);
    return _RideLeg(
      startedAt: startedAt,
      endAt: startedAt.add(_returnDuration),
      from: trip['dropoff'] as Map<String, dynamic>,
      targets: [trip['pickup'] as Map<String, dynamic>],
      reachedBefore: 0,
    );
  }

  static _RideLeg? _activeReturnOf(String id, DateTime now) {
    final back = _returnLegOf(id);
    return back == null || now.isBefore(back.startedAt) ? null : back;
  }

  static DateTime? _pinVerifiedAt(String id) => _pinRevealedAt[id]?.add(_pinVerifiedAfter);

  static void _reassignDriver(String id) {
    final trip = _stored(id);
    final currentId = (trip['driver'] as Map)['id'];
    final replacement = MockData.driverOffers.firstWhere(
      (offer) => offer['status'] != 'withdrawn' && (offer['driver'] as Map)['id'] != currentId,
    );
    trip['driver'] = {...(replacement['driver'] as Map<String, dynamic>)};
  }

  static Map<String, dynamic> _place(Object? json, Map<String, dynamic> fallback) {
    final place = json is Map ? Map<String, dynamic>.from(json) : fallback;
    final coordinates = place['coordinates'];
    final lat = coordinates is Map ? coordinates['lat'] : place['lat'] ?? place['latitude'];
    final lng = coordinates is Map ? coordinates['lng'] : place['lng'] ?? place['longitude'];
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

  static Map<String, dynamic> _livePlace(Map<String, dynamic> place) {
    final address = place['address'] as String? ?? '';
    return {'latitude': place['lat'], 'longitude': place['lng'], 'address': address.isEmpty ? place['name'] : address};
  }

  static const double routeDetour = _routeDetour;

  static Map<String, dynamic> stored(String id) => _stored(id);

  static String statusOf(String id) {
    _completeIfDue(id);
    return _status(id, DateTime.now());
  }

  static DateTime? completedAt(String id) => _completedAt[id];

  static String? deliveryItemName(String id) =>
      MockDeliveryLive.isDelivery(id) ? MockDeliveryLive.itemNameOf(id) : null;

  static Map<String, dynamic>? deliveryReceiptBlock(String id) =>
      MockDeliveryLive.receiptBlock(id, () => _deliveryClock(id));

  static Map<String, dynamic> payload(String id) => _payload(id);

  static Map<String, dynamic> ridePayload(String id) => _ridePayload(id);

  static Object? cancelRide(MockRequest request) => MockTripChanges.cancel(request);

  static Map<String, dynamic> cancelledPayload(String id, {required num fee}) => {
    'id': id,
    'status': 'cancelled',
    'cancelledBy': _cancelledBy[id],
    'cancellationFee': _naira(fee),
    'cancelledAt': _iso(_cancelledAt[id]!),
  };

  static DateTime createdAt(String id) => _createdAt(_stored(id));

  static Map<String, dynamic> placeOf(Object? json) => _place(json, MockRegion.fallbackPickup);

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
    final refusedAt = MockDeliveryLive.refusedAt(id, _pinVerifiedAt(id));
    if (refusedAt != null && !now.isBefore(refusedAt)) return 'cancelled';
    final back = _activeReturnOf(id, now);
    if (back != null) return now.isBefore(back.endAt) ? 'in_progress' : 'completed';
    final leg = _legOf(id);
    if (leg != null) return now.isBefore(leg.endAt) ? 'in_progress' : 'arrived_dropoff';
    final verifiedAt = _pinVerifiedAt(id);
    if (verifiedAt != null && !now.isBefore(verifiedAt)) return 'pin_verified';
    return now.difference(_createdAt(trip)) >= _arrivalAfter ? 'driver_arrived' : 'driver_en_route';
  }

  static String _rideStatus(String status) => switch (status) {
    'driver_en_route' => 'accepted',
    'pin_verified' => 'driver_arrived',
    'arrived_dropoff' => 'arrived_at_dropoff',
    _ => status,
  };

  static num _naira(num amount) => MockMoney.of(amount).major;

  static String _reference(String id) => 'SR-${10000000 + id.hashCode.abs() % 90000000}';

  static String _bookedFor(Object? rideFor) => switch (rideFor is Map ? rideFor['type'] : null) {
    'family' => 'family',
    'business' => 'business',
    'someone' => 'other',
    _ => 'self',
  };

  static String? _isoWhenReached(DateTime? time, DateTime now) => time == null || time.isAfter(now) ? null : _iso(time);

  static Map<String, dynamic> _liveDriver(Map<String, dynamic> trip) {
    final driver = trip['driver'] as Map<String, dynamic>;
    final vehicle = trip['vehicle'] as Map<String, dynamic>;
    return {
      'id': driver['id'],
      'firstName': driver['firstName'],
      'lastName': driver['lastName'],
      'displayName': driver['displayName'] ?? driver['name'],
      'photoUrl': driver['photoUrl'],
      'rating': driver['rating'],
      'ridesCompleted': driver['ridesCompleted'],
      'vehicle': {
        'make': vehicle['make'],
        'model': vehicle['model'],
        'year': vehicle['year'],
        'colour': vehicle['colour'],
        'plateNumber': vehicle['plateNumber'] ?? vehicle['plate'],
        'features': vehicle['features'] ?? const [],
        'featureLabels': vehicle['featureLabels'] ?? const [],
      },
    };
  }

  static Map<String, dynamic> _pinBlock(String id, String status, DateTime now) {
    final trip = _stored(id);
    final revealed = _pinRevealedAt.containsKey(id);
    final expiresAt = revealed ? DateTime.parse(trip['pinExpiresAt'] as String) : null;
    final verifiedAt = _pinVerifiedAt(id);
    final isVerified = verifiedAt != null && !now.isBefore(verifiedAt);
    return {
      'required': true,
      'digits': _pinCodes.first.length,
      'verified': isVerified,
      'available': status == 'driver_arrived' && _detailsConfirmedAt.containsKey(id) && !isVerified,
      'expiresAt': expiresAt == null ? null : _iso(expiresAt),
      'expired': expiresAt != null && !now.isBefore(expiresAt),
      'attemptsLeft': 5,
    };
  }

  static Map<String, dynamic> _timestamps(String id, DateTime now) {
    final created = _createdAt(_stored(id));
    final leg = _legOf(id);
    return {
      'acceptedAt': _iso(created),
      'arrivedAt': _isoWhenReached(created.add(_arrivalAfter), now),
      'waitStartedAt': null,
      'passengerArrivedAt': _isoWhenReached(_detailsConfirmedAt[id], now),
      'startedAt': _isoWhenReached(leg?.startedAt, now),
      'arrivedDropoffAt': _isoWhenReached(leg?.endAt, now),
      'completedAt': _isoWhenReached(_completedAt[id], now),
    };
  }

  static Map<String, dynamic> _ridePayload(String id) {
    _completeIfDue(id);
    final trip = _stored(id);
    final now = DateTime.now();
    final status = _status(id, now);
    final category = trip['category'] as String;
    final fare = _naira(trip['fare'] as num);
    final riderFare = _naira(trip['riderFare'] as num);
    final isPriced = status == 'arrived_dropoff' || status == 'completed';
    final isDelivery = MockDeliveryLive.isDelivery(id);
    return {
      'id': id,
      'ref': _reference(id),
      'status': _rideStatus(status),
      'kind': isDelivery ? 'delivery' : 'ride',
      'rideClass': {
        'id': category,
        'code': category,
        'name': 'Sanga ${category[0].toUpperCase()}${category.substring(1)}',
      },
      'pickup': _livePlace(trip['pickup'] as Map<String, dynamic>),
      'dropoff': _livePlace(trip['dropoff'] as Map<String, dynamic>),
      'stops': _liveStops(id, now),
      'pricingOption': 'standard',
      'tripType': 'one_way',
      'recommendedFare': riderFare,
      'boostAmount': 0,
      'offeredFare': null,
      'riderFare': riderFare,
      'discountAmount': 0,
      'agreedFare': fare,
      'finalFare': isPriced ? fare : null,
      'distanceKm': trip['distanceKm'],
      'durationMin': trip['durationMinutes'],
      'hourlyDurationMin': null,
      'scheduledFor': trip['scheduledAt'],
      'bookedFor': _bookedFor(trip['rideFor']),
      'passenger': null,
      'familyMemberId': null,
      'business': null,
      'preferences': null,
      'paymentMethod': MockTripState.paymentMethod[id] ?? 'cash',
      'driver': _liveDriver(trip),
      'package': null,
      'airport': MockAirport.tripBlock(id),
      'waitingFee': 0,
      'noShowFee': 0,
      'tipAmount': 0,
      'waiting': _waitBlock(id, trip),
      'pin': _pinBlock(id, status, now),
      'matching': null,
      'timestamps': _timestamps(id, now),
      'createdAt': _iso(_createdAt(trip)),
      'cancelledBy': ?_cancelledBy[id],
      'cancellationReason': ?(status == 'cancelled' ? _deliveryCancelReason(id) : null),
      'returnFee': ?(_returnLegOf(id) == null ? null : _naira(MockDeliveryLive.returnFee)),
      'delivery': ?MockDeliveryLive.tripBlock(id, () => _deliveryClock(id)),
    };
  }

  static String? _deliveryCancelReason(String id) {
    final reason = _cancelReasons[id] ?? _refusalReason(id);
    return const {'package_refused', 'delivery_cancelled', 'delivery_returned'}.contains(reason) ? reason : null;
  }

  static List<Map<String, dynamic>> _liveStops(String id, DateTime now) {
    final reached = _reachedStops(id, now);
    return [
      for (final (index, stop) in (_stored(id)['stops'] as List).indexed)
        {..._livePlace(stop as Map<String, dynamic>), 'status': index < reached ? 'reached' : 'pending'},
    ];
  }

  static void _completeIfDue(String id) {
    if (_completedAt.containsKey(id) || _cancelledAt.containsKey(id)) return;
    final leg = _legOf(id);
    if (leg == null) return;
    final completesAt = leg.endAt.add(_driverCompletesAfter);
    if (DateTime.now().isBefore(completesAt)) return;
    if (MockDeliveryLive.isDelivery(id) && !MockDeliveryLive.canComplete(id, _deliveryClock(id))) return;
    _completedAt[id] = completesAt;
    MockHistory.recordTrip(id, () => MockTripWrapUp.historyDetail(id));
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
      ..._waitBlock(id, trip),
      'driver': trip['driver'],
      'vehicle': trip['vehicle'],
      'pickup': _apiPlace(trip['pickup'] as Map<String, dynamic>),
      'stops': _apiStops(id, now),
      'dropoff': _apiPlace(trip['dropoff'] as Map<String, dynamic>),
      'fare': {
        'total': MockMoney.json(trip['fare'] as num),
        'counterOffer': MockMoney.jsonOrNull(trip['counterOffer'] as num?),
        'currency': MockMoney.currency,
      },
      if (showsPin) 'pin': trip['pin'],
      if (showsPin) 'pinExpiresAt': trip['pinExpiresAt'],
      if (status == 'driver_en_route') 'etaAt': _iso(now.add(_travelTime(_distanceRemaining(trip, status, position)))),
      if (status == 'in_progress') 'etaAt': _iso((_activeReturnOf(id, now) ?? _legOf(id)!).endAt),
      'distanceRemainingKm': _distanceRemaining(trip, status, position),
      'driverPosition': position,
      'unreadMessages': _unread(id, now),
      'events': _events(id),
      'cancellationReason': ?(_cancelReasons[id] ?? (status == 'cancelled' ? _refusalReason(id) : null)),
      'returnFee': ?(_returnLegOf(id) == null ? null : MockMoney.json(MockDeliveryLive.returnFee)),
      'airport': ?MockAirport.tripBlock(id),
      'delivery': ?MockDeliveryLive.tripBlock(id, () => _deliveryClock(id)),
    };
  }

  static Map<String, dynamic> _waitBlock(String id, Map<String, dynamic> trip) {
    final scheduledAt = DateTime.tryParse('${trip['scheduledAt']}');
    if (scheduledAt == null) return {'freeWaitSeconds': MockBooking.freeWaitSeconds(trip['category'] as String)};
    return {
      'freeWaitSeconds': 0,
      'scheduledPickupAt': _iso(scheduledAt),
      ...MockBooking.scheduledWaitJson(scheduledAt, isAirport: MockAirport.hasRide(id)),
    };
  }

  static String? _refusalReason(String id) {
    final refusedAt = MockDeliveryLive.refusedAt(id, _pinVerifiedAt(id));
    return refusedAt == null ? null : 'package_refused';
  }

  static Map<String, dynamic>? active() => _active();

  static Map<String, dynamic>? _active() {
    for (final id in MockTripState.trips.keys.toList().reversed) {
      final status = statusOf(id);
      if (status != 'completed' && status != 'cancelled') return _ridePayload(id);
    }
    return null;
  }

  static Object? _confirmDetails(MockRequest request) {
    final id = request.params['id']!;
    final status = _status(id, DateTime.now());
    if (status == 'driver_en_route') throw const MockFailure(409, 'Your driver is still on the way.');
    if (status != 'driver_arrived') throw const MockFailure(409, 'This trip has already moved on.');
    _detailsConfirmedAt.putIfAbsent(id, DateTime.now);
    return {'rideId': id, 'confirmed': true};
  }

  static Object? _revealPin(MockRequest request) {
    final id = request.params['id']!;
    final now = DateTime.now();
    if (_status(id, now) != 'driver_arrived' || !_detailsConfirmedAt.containsKey(id)) {
      throw const MockFailure(409, 'Your PIN isn’t available yet.', code: 'PASSENGER_NOT_CONFIRMED');
    }
    final trip = _stored(id);
    final isIssued = _pinRevealedAt.containsKey(id);
    final isExpired = isIssued && !now.isBefore(DateTime.parse(trip['pinExpiresAt'] as String));
    if (isExpired) _pinIndex[id] = ((_pinIndex[id] ?? 0) + 1) % _pinCodes.length;
    if (!isIssued || isExpired) {
      trip
        ..['pin'] = _pinCodes[_pinIndex[id] ?? 0]
        ..['pinExpiresAt'] = _iso(now.add(_pinWindow));
    }
    _pinRevealedAt.putIfAbsent(id, () => now);
    final expiresAt = DateTime.parse(trip['pinExpiresAt'] as String);
    return {
      'rideId': id,
      'pin': int.parse(trip['pin'] as String),
      'digits': (trip['pin'] as String).length,
      'expiresAt': _iso(expiresAt),
      'expiresInSec': expiresAt.difference(now).inSeconds,
    };
  }

  static Object? _report(MockRequest request) {
    final id = request.params['id']!;
    final reasons = request.body['reasons'];
    if (reasons is! List || reasons.isEmpty) throw const MockFailure(422, 'Pick at least one reason.');
    if (_cancelReasons[id] != 'driver_mismatch') {
      if (_status(id, DateTime.now()) != 'driver_arrived') {
        throw const MockFailure(409, 'This trip has already moved on.');
      }
      cancel(id, reason: 'driver_mismatch', by: 'rider');
    }
    return cancelledPayload(id, fee: 0);
  }

  static Object? _share(MockRequest request) {
    final id = request.params['id']!;
    _stored(id);
    final token = id.hashCode.abs().toRadixString(36);
    return {
      'url': 'https://sanga.ride/t/$token',
      'expiresAt': _iso(DateTime.now().add(const Duration(hours: 6))),
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Map<String, dynamic> _driverPosition(Map<String, dynamic> trip, String status, DateTime now) {
    final start = trip['driverStart'] as Map<String, dynamic>;
    final pickup = trip['pickup'] as Map<String, dynamic>;
    final dropoff = trip['dropoff'] as Map<String, dynamic>;
    final id = trip['id'] as String;
    final back = _activeReturnOf(id, now);
    if (back != null) return _legPosition(back, now);
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
      'in_progress' => _isReturning(trip) ? trip['pickup'] : trip['dropoff'],
      _ => null,
    };
    if (target == null) return null;
    return double.parse((_distanceKm(position, target as Map<String, dynamic>) * _routeDetour).toStringAsFixed(1));
  }

  static bool _isReturning(Map<String, dynamic> trip) => _activeReturnOf(trip['id'] as String, DateTime.now()) != null;

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
      ('pin_verified', _pinVerifiedAt(id)),
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

  static Object? _markMessagesRead(MockRequest request) {
    final id = request.params['id']!;
    _stored(id);
    _messagesReadAt[id] = DateTime.now();
    return {'rideId': id, 'read': true};
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
    final existing = _riderMessages[id]?.where((message) => message['clientId'] == clientId).firstOrNull;
    if (clientId != null && existing != null) return existing;
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
