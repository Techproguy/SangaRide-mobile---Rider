import 'dart:math' as math;

import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/mock/mock_groups.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride_core/mock.dart' show NetworkLab;

abstract final class MockRideRequests {
  static final List<MockRoute> routes = [
    MockRoute.get(AppEndpoints.rideOptions, (_) => MockData.rideOptions),
    MockRoute.post(AppEndpoints.rideEstimate, _rideEstimate),
    MockRoute.post(AppEndpoints.rideRequests, _createRideRequest),
    MockRoute.get(AppEndpoints.rideRequest, _rideRequestStatus),
    MockRoute.get(AppEndpoints.rideRequestOffers, _rideOffers),
    MockRoute.post(AppEndpoints.rideOfferIgnore, (_) => null),
    MockRoute.post(AppEndpoints.rideOfferHold, _holdOffer),
    MockRoute.delete(AppEndpoints.rideRequestHold, (_) => null),
    MockRoute.post(AppEndpoints.rideOfferConfirm, _confirmOffer),
    MockRoute.post(AppEndpoints.rideRequestCancel, _cancelRideRequest),
  ];

  static final Map<String, _MockRideRequest> _rideRequests = {};
  static final Map<String, DateTime> _quotes = {};
  static final Map<String, Map<String, num>> _quotePrices = {};
  static int _rideRequestCount = 0;
  static int _quoteCount = 0;

  static void reset() {
    _rideRequests.clear();
    _quotes.clear();
    _quotePrices.clear();
  }

  static ({String id, String status})? activeRideRequest() {
    for (final entry in _rideRequests.entries.toList().reversed) {
      if (entry.value.isCancelled || MockTripState.trips.containsKey(entry.key)) continue;
      final status = _requestStatus(entry.value);
      if (_liveRequestStatuses.contains(status)) return (id: entry.key, status: status);
    }
    return null;
  }

  static const Set<String> _liveRequestStatuses = {'requested'};

  static const Duration _searchWindow = Duration(seconds: 60);
  static const Duration _holdWindow = Duration(seconds: 120);
  static const Duration _quoteLifetime = Duration(minutes: 5);
  static const Duration _checkingAfter = Duration(milliseconds: 1500);
  static const Duration _sendingAfter = Duration(milliseconds: 3000);
  static const Duration _resolvedAfter = Duration(milliseconds: 4500);

  static DateTime _now() => NetworkLab.instance.serverNow();

  static String _isoNow() => _now().toIso8601String();

  static const List<String> _matchStepCodes = ['searching', 'availability', 'sending', 'matching'];

  static String _stepState(int index, int done) => switch (index - done) {
    < 0 => 'done',
    0 => 'active',
    _ => 'pending',
  };

  static List<Map<String, dynamic>> _matchSteps(int done) => [
    for (final (index, label) in MockData.matchStepLabels.indexed)
      {'code': _matchStepCodes[index % _matchStepCodes.length], 'label': label, 'state': _stepState(index, done)},
  ];

  static Map<String, dynamic> _requestPayload(String id, String status, int stepsDone) => {
    'id': id,
    'status': status,
    'kind': 'ride',
    'matching': {'round': 1, 'expiresAt': _now().add(_searchWindow).toIso8601String(), 'steps': _matchSteps(stepsDone)},
  };

  static _MockRideRequest _requireRideRequest(MockRequest request) {
    final record = _rideRequests[request.params['id']];
    if (record == null) throw const MockFailure(404, 'We can’t find that ride request.', code: 'not_found');
    return record;
  }

  static Map<String, dynamic> _requireOffer(MockRequest request) {
    final offer = MockData.driverOffers.where((offer) => offer['id'] == request.params['offerId']).firstOrNull;
    if (offer == null) throw const MockFailure(404, 'We can’t find that driver offer.', code: 'not_found');
    return offer;
  }

  static void _checkQuote(Map<String, dynamic> body) {
    final quoteId = body['quoteId'];
    if (quoteId == null) return;
    final expiresAt = _quotes[quoteId];
    if (expiresAt != null && !expiresAt.isAfter(_now())) {
      throw const MockFailure(409, 'That price has expired. Have a look at the new one.', code: 'quote_expired');
    }
  }

  static Object? _createRideRequest(MockRequest request) {
    final body = request.body['delivery'] != null ? request.body : _fixtureBody(request.body);
    MockGroups.guardRide(body);
    _checkQuote(body);
    if (body['airport'] != null) {
      final decision = MockAirport.decide(body);
      if (!decision.isLive) return MockBooking.scheduleAirport(body, decision);
    }
    if (body['scheduledAt'] != null || body['repeat'] != null) return MockBooking.schedule(body);
    if (body['delivery'] != null) MockDelivery.validateRequest(body);
    final id = 'req_${++_rideRequestCount}';
    MockTrip.requests[id] = body;
    _rideRequests[id] = _MockRideRequest(
      createdAt: DateTime.now(),
      pricingMode: body['pricingMode'] as String?,
      proposedFare: MockMoney.naira(body['proposedFare']).toInt(),
      isFixedFare: body['delivery'] != null,
    );
    return {..._requestPayload(id, 'requested', 0), 'createdAt': _isoNow()};
  }

  static Map<String, dynamic> _fixtureBody(Map<String, dynamic> body) {
    final pricing = body['pricingOption'] as String?;
    final fare = body['offeredFare'] ?? _quotePrices[body['quoteId']]?[pricing] ?? 0;
    return {
      ...body,
      'optionId': body['rideClassId'],
      'pickup': _fixturePlace(body['pickup']),
      'stops': [for (final stop in body['stops'] as List? ?? const []) _fixturePlace(stop)],
      'dropoff': _fixturePlace(body['dropoff']),
      'rideFor': _fixtureRideFor(body),
      'pricingMode': pricing,
      'proposedFare': MockMoney.json(fare as num),
      'scheduledAt': body['scheduledFor'],
    };
  }

  static Map<String, dynamic>? _fixturePlace(Object? place) {
    if (place is! Map) return null;
    return {
      'place_id': place['placeId'] ?? '',
      'name': place['name'],
      'address': place['address'],
      'coordinates': {'lat': place['latitude'], 'lng': place['longitude']},
    };
  }

  static Map<String, dynamic> _fixtureRideFor(Map<String, dynamic> body) {
    final business = body['business'];
    return switch (body['bookedFor']) {
      'family' => {
        'type': 'family',
        'groupId': MockGroups.groupIdOfMember(body['familyMemberId'] as String?),
        'memberId': body['familyMemberId'],
      },
      'business' when business is Map => {'type': 'business', ...business},
      'other' => {'type': 'someone', 'passenger': body['passenger']},
      _ => {'type': 'me'},
    };
  }

  static Object? _rideRequestStatus(MockRequest request) {
    final id = request.params['id']!;
    if (MockTripState.trips.containsKey(id)) return MockTrip.ridePayload(id);
    final ride = MockHistory.liveRideOf(id) ?? MockBooking.liveRideOf(id);
    if (ride != null) return ride;
    final record = _requireRideRequest(request);
    return _requestPayload(id, _requestStatus(record), _stepsDone(record));
  }

  static String _requestStatus(_MockRideRequest record) {
    if (record.isCancelled) return 'cancelled';
    if (_hasResolved(record) && record.pricingMode == 'saver') return 'no_driver_found';
    return 'requested';
  }

  static bool _hasResolved(_MockRideRequest record) => DateTime.now().difference(record.createdAt) >= _resolvedAfter;

  static int _stepsDone(_MockRideRequest record) {
    final elapsed = DateTime.now().difference(record.createdAt);
    if (elapsed < _checkingAfter) return 0;
    if (elapsed < _sendingAfter) return 1;
    if (elapsed < _resolvedAfter) return 2;
    return record.pricingMode == 'saver' ? 3 : 4;
  }

  static int? _counterOffer(Map<String, dynamic> offer, num fare, {bool isFixed = false}) {
    final markup = isFixed ? null : offer['counterMarkup'] as num?;
    return markup == null ? null : ((fare * (1 + markup)) / 50).round() * 50;
  }

  static Map<String, dynamic> _priced(Map<String, dynamic> offer, num fare, {bool isFixed = false}) {
    final counter = _counterOffer(offer, fare, isFixed: isFixed);
    return {
      ...offer..remove('counterMarkup'),
      'type': counter == null ? 'accept' : 'counter',
      'amount': MockMoney.json(counter ?? fare),
      'counterOfferAmount': MockMoney.jsonOrNull(counter),
      'fee': MockMoney.json(counter ?? fare),
      'expiresAt': _now().add(_holdWindow).toIso8601String(),
      'vehicle': MockData.driverVehicle,
    };
  }

  static Object? _rideOffers(MockRequest request) {
    final record = _requireRideRequest(request);
    if (!_hasResolved(record) || _requestStatus(record) != 'requested') return const <Object>[];
    return [
      for (final offer in MockData.driverOffers)
        _priced(Map.of(offer), record.proposedFare, isFixed: record.isFixedFare),
    ];
  }

  static Map<String, dynamic> _driverCard(Map<String, dynamic> offer) => {
    ...(offer['driver'] as Map<String, dynamic>),
    'vehicle': MockData.driverVehicle,
    'distanceAwayKm': offer['distanceKm'],
  };

  static const _offerUnavailable = MockFailure(409, 'That driver is no longer available.', code: 'offer_unavailable');

  static Object? _holdOffer(MockRequest request) {
    final record = _requireRideRequest(request);
    final offer = _requireOffer(request);
    if (offer['status'] == 'withdrawn') throw _offerUnavailable;
    final counter = _counterOffer(offer, record.proposedFare, isFixed: record.isFixedFare);
    return {
      'offerId': offer['id'],
      'status': 'selected',
      'confirmExpiresAt': _now().add(_holdWindow).toIso8601String(),
      'confirmWindowSec': _holdWindow.inSeconds,
      'driver': offer['driver'],
      'vehicle': MockData.driverVehicle,
      'distanceKm': offer['distanceKm'],
      'etaMin': offer['etaMin'],
      'matchLabel': offer['matchLabel'],
      'fee': MockMoney.json(counter ?? record.proposedFare),
      'counterOfferAmount': MockMoney.jsonOrNull(counter),
    };
  }

  static Object? _confirmOffer(MockRequest request) {
    final record = _requireRideRequest(request);
    final offer = _requireOffer(request);
    if (offer['status'] == 'withdrawn') throw _offerUnavailable;
    final requestId = request.params['id']!;
    final tripId = requestId;
    if (!MockTripState.trips.containsKey(tripId)) {
      MockAirport.attachLive(tripId, MockTrip.requests[requestId]);
      MockTrip.open(
        tripId: tripId,
        request: MockTrip.requests[requestId] ?? const {},
        driverCard: _driverCard(offer),
        proposedFare: record.proposedFare,
        counterOffer: _counterOffer(offer, record.proposedFare, isFixed: record.isFixedFare),
        etaMinutes: offer['etaMinutes'] as num,
      );
    }
    return {
      'ride': {'id': tripId, 'status': 'accepted', 'acceptedAt': _isoNow()},
      'driver': offer['driver'],
      'vehicle': MockData.driverVehicle,
      'etaMin': offer['etaMin'],
      'title': 'Ride accepted',
    };
  }

  static Object? _cancelRideRequest(MockRequest request) {
    if (MockTripState.trips.containsKey(request.params['id'])) return MockTrip.cancelRide(request);
    if (MockBooking.isScheduled(request.params['id']!)) return MockBooking.cancel(request);
    _requireRideRequest(request).isCancelled = true;
    return {'status': 'cancelled'};
  }

  static Object? _rideEstimate(MockRequest request) {
    final tripType = request.body['tripType'];
    final optionId = request.body['rideClassId'] as String;
    final boost = tripType == 'hourly' ? 0 : 500;
    final meetGreetFee = MockAirport.meetGreetFee(request.body);
    if (tripType == 'hourly') {
      final rate = MockBooking.hourlyRatesNaira.firstWhere((rate) => rate['category'] == optionId)['hourlyRate'] as num;
      final hours = ((request.body['hourlyDurationMin'] as num?) ?? 120) ~/ 60;
      return _fare(
        baseFare: 0,
        distanceKm: 0,
        distanceFare: hours * rate,
        boost: boost,
        fee: 0,
        extra: {'hours': hours, 'hourlyRate': MockMoney.json(rate)},
      );
    }
    final points = [
      request.body['pickup'],
      ...request.body['stops'] as List,
      request.body['dropoff'],
    ].map((place) => {'lat': (place as Map)['latitude'], 'lng': place['longitude']}).toList();
    var km = 0.0;
    for (var i = 1; i < points.length; i++) {
      km += _distanceKm(points[i - 1], points[i]);
    }
    final isIntercity = tripType == 'intercity';
    km = (km * 1.3).clamp(1, isIntercity ? 700 : 200).toDouble();
    final pricePerKm = MockData.perKmRateNaira(optionId);
    final rate = isIntercity ? pricePerKm * 0.35 : pricePerKm;
    final legs = tripType == 'round_trip' ? 2 : 1;
    final baseFare = isIntercity ? 5000 : 500;
    final distanceFare = (km * rate / 10).round() * 10 * legs;
    return _fare(
      baseFare: baseFare,
      distanceKm: double.parse((km * legs).toStringAsFixed(1)),
      distanceFare: distanceFare,
      boost: boost,
      fee: meetGreetFee,
      extra: {
        'rideClass': {'id': optionId, 'perKmRate': MockMoney.perDistanceJson(rate)},
      },
    );
  }

  static Map<String, dynamic> _fare({
    required num baseFare,
    required num distanceKm,
    required num distanceFare,
    required num boost,
    required num fee,
    required Map<String, dynamic> extra,
  }) {
    final total = baseFare + distanceFare + boost + fee;
    final quoteId = 'quote_${++_quoteCount}';
    final expiresAt = _now().add(_quoteLifetime);
    _quotes[quoteId] = expiresAt;
    num rounded(num amount) => (amount / 10).round() * 10;
    final minimumOffer = rounded(total * 0.6);
    _quotePrices[quoteId] = {
      'standard': total,
      'fair': minimumOffer,
      'saver': rounded(total * 0.75),
      'priority': rounded(total * 1.4),
    };
    return {
      'quoteId': quoteId,
      'expiresAt': expiresAt.toIso8601String(),
      'distanceKm': distanceKm,
      'lines': [
        {'code': 'base_fare', 'label': 'Base fare', 'amount': MockMoney.json(baseFare)},
        {'code': 'distance', 'label': 'Distance', 'amount': MockMoney.json(distanceFare)},
        {'code': 'discount', 'label': 'Discount', 'amount': MockMoney.json(0)},
        {'code': 'boost', 'label': 'Boost', 'amount': MockMoney.json(boost)},
        if (fee > 0) {'code': 'meet_greet', 'label': 'Meet and greet', 'amount': MockMoney.json(fee)},
      ],
      'total': MockMoney.json(total),
      ...extra,
      'minimumOffer': MockMoney.json(minimumOffer),
      'maximumOffer': MockMoney.json(total),
      'pricingOptions': [
        for (final MapEntry(key: code, value: price) in _quotePrices[quoteId]!.entries)
          {'code': code, 'label': _pricingLabels[code], 'price': MockMoney.json(price)},
      ],
    };
  }

  static const Map<String, String> _pricingLabels = {
    'standard': 'Standard',
    'fair': 'Fair Fare',
    'saver': 'Saver',
    'priority': 'Priority',
  };

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
}

class _MockRideRequest {
  _MockRideRequest({
    required this.createdAt,
    required this.pricingMode,
    required this.proposedFare,
    this.isFixedFare = false,
  });

  final DateTime createdAt;
  final String? pricingMode;
  final int proposedFare;
  final bool isFixedFare;
  bool isCancelled = false;
}
