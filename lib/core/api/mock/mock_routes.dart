import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/mock/mock_who_for.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_safety.dart';
import 'package:sanga_ride/core/api/mock/mock_notifications.dart';
import 'package:sanga_ride/core/api/mock/mock_saved_places.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_support.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_wrapup.dart';
import 'package:sanga_ride/core/api/mock/mock_verification.dart';
import 'package:sanga_ride/core/api/mock/mock_wallet.dart';

class MockRoutes {
  MockRoutes._();

  static final List<MockRoute> all = [
    ...MockBooking.routes,
    ...MockAirport.routes,
    ...MockWhoFor.routes,
    ...MockDelivery.routes,
    ...MockTrip.routes,
    ...MockSafety.routes,
    ...MockTripWrapUp.routes,
    ...MockSavedPlaces.routes,
    ...MockHistory.routes,
    ...MockAccount.routes,
    ...MockNotifications.routes,
    ...MockVerification.routes,
    ...MockSupport.routes,
    ...MockWallet.routes,
    MockRoute.post(MockEndpoints.signUp, (request) => {'phone': request.body['phone'], 'expiresInSeconds': 300}),
    MockRoute.post(
      MockEndpoints.checkExistence,
      (request) => {'exists': request.body['phone'] == MockData.user['phone']},
    ),
    MockRoute.post(MockEndpoints.requestOtp, _requestOtp),
    MockRoute.post(MockEndpoints.verifyOtp, _verifyOtp),
    MockRoute.post(MockEndpoints.googleSignIn, (_) => _session),
    MockRoute.post(MockEndpoints.appleSignIn, (_) => _session),
    MockRoute.post(MockEndpoints.refreshToken, (_) => MockData.tokens),
    MockRoute.post(MockEndpoints.logout, (_) => null),
    MockRoute.post(MockEndpoints.selfie, MockVerification.selfie),
    MockRoute.get(MockEndpoints.recentPlaces, (_) => _recentPlaces),
    MockRoute.post(MockEndpoints.recentPlaces, _addRecentPlace),
    MockRoute.delete(MockEndpoints.recentPlace, (request) {
      _recentPlaces.removeWhere((place) => place['place_id'] == request.params['id']);
      return null;
    }),
    MockRoute.get(MockEndpoints.weather, (_) => MockData.weather),
    MockRoute.get(MockEndpoints.rideOptions, (_) => MockData.rideOptions),
    MockRoute.post(MockEndpoints.rideEstimate, _rideEstimate),
    MockRoute.post(MockEndpoints.rideRequests, _createRideRequest),
    MockRoute.post(MockEndpoints.rideRequestsScheduled, _scheduleRide),
    MockRoute.get(MockEndpoints.rideRequest, _rideRequestStatus),
    MockRoute.get(MockEndpoints.rideRequestOffers, _rideOffers),
    MockRoute.post(MockEndpoints.rideOfferIgnore, (_) => null),
    MockRoute.post(MockEndpoints.rideOfferHold, _holdOffer),
    MockRoute.delete(MockEndpoints.rideRequestHold, (_) => null),
    MockRoute.post(MockEndpoints.rideOfferConfirm, _confirmOffer),
    MockRoute.post(MockEndpoints.rideRequestCancel, _cancelRideRequest),
  ];

  static final Map<String, _MockRideRequest> _rideRequests = {};

  static const Duration _searchWindow = Duration(seconds: 60);
  static const Duration _holdWindow = Duration(seconds: 120);
  static const Duration _checkingAfter = Duration(milliseconds: 1500);
  static const Duration _sendingAfter = Duration(milliseconds: 3000);
  static const Duration _resolvedAfter = Duration(milliseconds: 4500);

  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  static List<Map<String, dynamic>> _matchSteps(int done) => [
    for (final (index, label) in MockData.matchStepLabels.indexed)
      {'key': 'step_${index + 1}', 'label': label, 'done': index < done},
  ];

  static Map<String, dynamic> _requestPayload(String id, String status, int stepsDone) => {
    'id': id,
    'status': status,
    'searchExpiresAt': DateTime.now().toUtc().add(_searchWindow).toIso8601String(),
    'serverTime': _isoNow(),
    'steps': _matchSteps(stepsDone),
  };

  static _MockRideRequest _requireRideRequest(MockRequest request) {
    final record = _rideRequests[request.params['id']];
    if (record == null) throw const MockFailure(404, 'We can’t find that ride request.');
    return record;
  }

  static Map<String, dynamic> _requireOffer(MockRequest request) {
    final offer = MockData.driverOffers.where((offer) => offer['id'] == request.params['offerId']).firstOrNull;
    if (offer == null) throw const MockFailure(404, 'We can’t find that driver offer.');
    return offer;
  }

  static Object? _createRideRequest(MockRequest request) {
    if (request.body['airport'] != null) {
      final decision = MockAirport.decide(request.body);
      if (!decision.isLive) return MockBooking.scheduleAirport(request.body, decision);
    }
    if (request.body['delivery'] != null) MockDelivery.validateRequest(request.body);
    final id = 'req_${_rideRequests.length + 1}';
    MockTrip.requests[id] = request.body;
    _rideRequests[id] = _MockRideRequest(
      createdAt: DateTime.now(),
      pricingMode: request.body['pricingMode'] as String?,
      proposedFare: (request.body['proposedFare'] as num?)?.toInt() ?? 0,
      isFixedFare: request.body['delivery'] != null,
    );
    return {..._requestPayload(id, 'searching', 1), 'createdAt': _isoNow()};
  }

  static Object? _scheduleRide(MockRequest request) {
    final scheduledAt = request.body['scheduledAt'];
    if (scheduledAt == null) throw const MockFailure(422, 'Pick a time for your ride.');
    return {
      'id': 'sched_${_rideRequests.length + 1}',
      'status': 'scheduled',
      'scheduledAt': scheduledAt,
      'serverTime': _isoNow(),
    };
  }

  static Object? _rideRequestStatus(MockRequest request) {
    final record = _requireRideRequest(request);
    final id = request.params['id']!;
    if (record.isCancelled) return _requestPayload(id, 'cancelled', 0);
    final elapsed = DateTime.now().difference(record.createdAt);
    if (elapsed < _checkingAfter) return _requestPayload(id, 'searching', 1);
    if (elapsed < _sendingAfter) return _requestPayload(id, 'checking', 2);
    if (elapsed < _resolvedAfter) return _requestPayload(id, 'sending', 3);
    if (record.pricingMode == 'saver') return _requestPayload(id, 'no_driver_found', 3);
    return _requestPayload(id, 'offers', 4);
  }

  static Map<String, dynamic> _priced(Map<String, dynamic> offer, num fare, {bool isFixed = false}) {
    final markup = isFixed ? null : offer['counterMarkup'] as num?;
    return {
      ...offer..remove('counterMarkup'),
      'counterOffer': markup == null ? null : ((fare * (1 + markup)) / 50).round() * 50,
    };
  }

  static Object? _rideOffers(MockRequest request) {
    final record = _requireRideRequest(request);
    return {
      'offers': [for (final offer in MockData.driverOffers) _priced(Map.of(offer), record.proposedFare, isFixed: record.isFixedFare)],
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
        'holdExpiresAt': DateTime.now().toUtc().add(_holdWindow).toIso8601String(),
        'serverTime': _isoNow(),
        'fare': record.proposedFare,
        'counterOffer': _priced(Map.of(offer), record.proposedFare, isFixed: record.isFixedFare)['counterOffer'],
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
    MockAirport.attachLive(tripId, MockTrip.requests[requestId]);
    MockTrip.open(
      tripId: tripId,
      request: MockTrip.requests[requestId] ?? const {},
      driverCard: _driverCard(offer),
      proposedFare: record.proposedFare,
      counterOffer: (_priced(Map.of(offer), record.proposedFare, isFixed: record.isFixedFare)['counterOffer'] as num?)?.toInt(),
      etaMinutes: offer['etaMinutes'] as num,
    );
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

  static const int _maxRecentPlaces = 5;

  static final List<Map<String, dynamic>> _recentPlaces = [...MockData.recentPlaces];

  static Object? _addRecentPlace(MockRequest request) {
    final place = Map<String, dynamic>.from(request.body);
    _recentPlaces
      ..removeWhere((recent) => recent['place_id'] == place['place_id'])
      ..insert(0, place);
    if (_recentPlaces.length > _maxRecentPlaces) _recentPlaces.removeRange(_maxRecentPlaces, _recentPlaces.length);
    return place;
  }

  static Map<String, dynamic> get _session => {'tokens': MockData.tokens, 'user': MockData.user};

  static Object? _requestOtp(MockRequest request) {
    final isLogin = request.body['purpose'] == 'login';
    if (isLogin && request.body['phone'] == MockData.unregisteredPhone) {
      throw const MockFailure(404, 'We can’t find an account with this number.');
    }
    return {'phone': request.body['phone'], 'expiresInSeconds': 300};
  }

  static Object? _rideEstimate(MockRequest request) {
    final tripType = request.body['tripType'];
    final optionId = request.body['optionId'] as String;
    final boost = tripType == 'hourly' ? 0 : 500;
    final meetGreetFee = MockAirport.meetGreetFee(request.body);
    if (tripType == 'hourly') {
      final rates = (MockBooking.hourlyRates['rates'] as List).cast<Map<String, dynamic>>();
      final rate = rates.firstWhere((rate) => rate['category'] == optionId)['hourlyRate'] as num;
      final hours = (request.body['hours'] as num?)?.toInt() ?? 2;
      return _fare(
        baseFare: 0,
        distanceKm: 0,
        distanceFare: hours * rate,
        boost: boost,
        fee: 0,
        extra: {'hours': hours, 'hourlyRate': rate},
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
    final rate = isIntercity ? (request.body['pricePerKm'] as num) * 0.35 : request.body['pricePerKm'] as num;
    final legs = tripType == 'roundTrip' ? 2 : 1;
    final baseFare = isIntercity ? 5000 : 500;
    final distanceFare = (km * rate / 10).round() * 10 * legs;
    return _fare(
      baseFare: baseFare,
      distanceKm: double.parse((km * legs).toStringAsFixed(1)),
      distanceFare: distanceFare,
      boost: boost,
      fee: meetGreetFee,
      extra: {'ratePerKm': rate},
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
    return {
      'baseFare': baseFare,
      'distanceKm': distanceKm,
      'distanceFare': distanceFare,
      'discount': 0,
      'boost': boost,
      'total': total,
      if (fee > 0) 'meetGreetFee': fee,
      ...extra,
      'pricing': {
        'standard': total,
        'fairFare': (total * 0.9 / 10).round() * 10,
        'saver': (total * 0.75 / 10).round() * 10,
        'priority': (total * 1.4 / 10).round() * 10,
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

  static Object? _verifyOtp(MockRequest request) {
    if (request.body['code'] != MockData.otpCode) {
      throw const MockFailure(400, "That code didn't match. Give it another go.");
    }
    return _session;
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
