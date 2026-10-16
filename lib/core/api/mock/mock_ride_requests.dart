import 'dart:math' as math;

import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/mock/mock_groups.dart';
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
  static int _rideRequestCount = 0;
  static int _quoteCount = 0;

  static void reset() {
    _rideRequests.clear();
    _quotes.clear();
  }

  static ({String id, String status})? activeRideRequest() {
    for (final entry in _rideRequests.entries.toList().reversed) {
      if (entry.value.isCancelled || MockTripState.trips.containsKey('trip_${entry.key}')) continue;
      final status = _requestStatus(entry.value);
      if (_liveRequestStatuses.contains(status)) return (id: entry.key, status: status);
    }
    return null;
  }

  static const Set<String> _liveRequestStatuses = {'searching', 'checking', 'sending', 'offers'};

  static const Duration _searchWindow = Duration(seconds: 60);
  static const Duration _holdWindow = Duration(seconds: 120);
  static const Duration _quoteLifetime = Duration(minutes: 5);
  static const Duration _checkingAfter = Duration(milliseconds: 1500);
  static const Duration _sendingAfter = Duration(milliseconds: 3000);
  static const Duration _resolvedAfter = Duration(milliseconds: 4500);

  static DateTime _now() => NetworkLab.instance.serverNow();

  static String _isoNow() => _now().toIso8601String();

  static List<Map<String, dynamic>> _matchSteps(int done) => [
    for (final (index, label) in MockData.matchStepLabels.indexed)
      {'key': 'step_${index + 1}', 'label': label, 'done': index < done},
  ];

  static Map<String, dynamic> _requestPayload(String id, String status, int stepsDone) => {
    'id': id,
    'status': status,
    'searchExpiresAt': _now().add(_searchWindow).toIso8601String(),
    'serverTime': _isoNow(),
    'steps': _matchSteps(stepsDone),
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
    MockGroups.guardRide(request.body);
    _checkQuote(request.body);
    if (request.body['airport'] != null) {
      final decision = MockAirport.decide(request.body);
      if (!decision.isLive) return MockBooking.scheduleAirport(request.body, decision);
    }
    if (request.body['delivery'] != null) MockDelivery.validateRequest(request.body);
    final id = 'req_${++_rideRequestCount}';
    MockTrip.requests[id] = request.body;
    _rideRequests[id] = _MockRideRequest(
      createdAt: DateTime.now(),
      pricingMode: request.body['pricingMode'] as String?,
      proposedFare: MockMoney.naira(request.body['proposedFare']).toInt(),
      isFixedFare: request.body['delivery'] != null,
    );
    return {..._requestPayload(id, 'searching', 1), 'createdAt': _isoNow()};
  }

  static Object? _rideRequestStatus(MockRequest request) {
    final record = _requireRideRequest(request);
    final id = request.params['id']!;
    final status = _requestStatus(record);
    return _requestPayload(id, status, _stepsDoneFor(status));
  }

  static String _requestStatus(_MockRideRequest record) {
    if (record.isCancelled) return 'cancelled';
    final elapsed = DateTime.now().difference(record.createdAt);
    if (elapsed < _checkingAfter) return 'searching';
    if (elapsed < _sendingAfter) return 'checking';
    if (elapsed < _resolvedAfter) return 'sending';
    return record.pricingMode == 'saver' ? 'no_driver_found' : 'offers';
  }

  static int _stepsDoneFor(String status) => switch (status) {
    'searching' => 1,
    'checking' => 2,
    'sending' || 'no_driver_found' => 3,
    'offers' => 4,
    _ => 0,
  };

  static int? _counterOffer(Map<String, dynamic> offer, num fare, {bool isFixed = false}) {
    final markup = isFixed ? null : offer['counterMarkup'] as num?;
    return markup == null ? null : ((fare * (1 + markup)) / 50).round() * 50;
  }

  static Map<String, dynamic> _priced(Map<String, dynamic> offer, num fare, {bool isFixed = false}) {
    final counterOffer = MockMoney.jsonOrNull(_counterOffer(offer, fare, isFixed: isFixed));
    return {...offer..remove('counterMarkup'), 'counterOffer': counterOffer};
  }

  static Object? _rideOffers(MockRequest request) {
    final record = _requireRideRequest(request);
    return {
      'offers': [
        for (final offer in MockData.driverOffers)
          _priced(Map.of(offer), record.proposedFare, isFixed: record.isFixedFare),
      ],
    };
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
    return {
      'hold': {
        'offerId': offer['id'],
        'holdExpiresAt': _now().add(_holdWindow).toIso8601String(),
        'serverTime': _isoNow(),
        'fare': MockMoney.json(record.proposedFare),
        'counterOffer': MockMoney.jsonOrNull(_counterOffer(offer, record.proposedFare, isFixed: record.isFixedFare)),
        'matchLabel': offer['matchLabel'],
      },
      'driver': _driverCard(offer),
    };
  }

  static Object? _confirmOffer(MockRequest request) {
    final record = _requireRideRequest(request);
    final offer = _requireOffer(request);
    if (offer['status'] == 'withdrawn') throw _offerUnavailable;
    final requestId = request.params['id']!;
    final tripId = 'trip_$requestId';
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
      'tripId': tripId,
      'status': 'driver_confirmed',
      'driver': _driverCard(offer),
      'etaMinutes': offer['etaMinutes'],
    };
  }

  static Object? _cancelRideRequest(MockRequest request) {
    _requireRideRequest(request).isCancelled = true;
    return {'status': 'cancelled'};
  }

  static Object? _rideEstimate(MockRequest request) {
    final tripType = request.body['tripType'];
    final optionId = request.body['optionId'] as String;
    final boost = tripType == 'hourly' ? 0 : 500;
    final meetGreetFee = MockAirport.meetGreetFee(request.body);
    if (tripType == 'hourly') {
      final rate = MockBooking.hourlyRatesNaira.firstWhere((rate) => rate['category'] == optionId)['hourlyRate'] as num;
      final hours = (request.body['hours'] as num?)?.toInt() ?? 2;
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
    ].map((place) => (place as Map)['coordinates'] as Map).toList();
    var km = 0.0;
    for (var i = 1; i < points.length; i++) {
      km += _distanceKm(points[i - 1], points[i]);
    }
    final isIntercity = tripType == 'intercity';
    km = (km * 1.3).clamp(1, isIntercity ? 700 : 200).toDouble();
    final pricePerKm = MockMoney.nairaPerKilometer(request.body['pricePerKm']);
    final rate = isIntercity ? pricePerKm * 0.35 : pricePerKm;
    final legs = tripType == 'roundTrip' ? 2 : 1;
    final baseFare = isIntercity ? 5000 : 500;
    final distanceFare = (km * rate / 10).round() * 10 * legs;
    return _fare(
      baseFare: baseFare,
      distanceKm: double.parse((km * legs).toStringAsFixed(1)),
      distanceFare: distanceFare,
      boost: boost,
      fee: meetGreetFee,
      extra: {'ratePerKm': MockMoney.perDistanceJson(rate)},
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
    return {
      'quoteId': quoteId,
      'expiresAt': expiresAt.toIso8601String(),
      'baseFare': MockMoney.json(baseFare),
      'distanceKm': distanceKm,
      'distanceFare': MockMoney.json(distanceFare),
      'discount': MockMoney.json(0),
      'boost': MockMoney.json(boost),
      'total': MockMoney.json(total),
      if (fee > 0) 'meetGreetFee': MockMoney.json(fee),
      ...extra,
      'fairFareRange': {'min': MockMoney.json((total * 0.6 / 10).round() * 10), 'max': MockMoney.json(total)},
      'pricing': {
        'standard': MockMoney.json(total),
        'saver': MockMoney.json((total * 0.75 / 10).round() * 10),
        'priority': MockMoney.json((total * 1.4 / 10).round() * 10),
      },
    };
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
