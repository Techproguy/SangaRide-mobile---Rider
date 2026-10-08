import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

class MockRoutes {
  MockRoutes._();

  static final List<MockRoute> all = [
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
    MockRoute.get(MockEndpoints.me, (_) => MockData.user),
    MockRoute.patch(MockEndpoints.me, (request) => {...MockData.user, ...request.body}),
    MockRoute.post(MockEndpoints.homeAddress, (request) => request.body),
    MockRoute.post(MockEndpoints.selfie, (_) => {'status': 'verified'}),
    MockRoute.get(MockEndpoints.recentPlaces, (_) => _recentPlaces),
    MockRoute.post(MockEndpoints.recentPlaces, _addRecentPlace),
    MockRoute.delete(MockEndpoints.recentPlace, (request) {
      _recentPlaces.removeWhere((place) => place['place_id'] == request.params['id']);
      return null;
    }),
    MockRoute.get(MockEndpoints.savedPlaces, (_) => MockData.savedPlaces),
    MockRoute.get(MockEndpoints.weather, (_) => MockData.weather),
    MockRoute.get(MockEndpoints.rideOptions, (_) => MockData.rideOptions),
    MockRoute.post(MockEndpoints.rideEstimate, _rideEstimate),
  ];

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
    final points = [
      request.body['pickup'],
      ...request.body['stops'] as List,
      request.body['dropoff'],
    ].map((place) => (place as Map)['coordinates'] as Map).toList();
    var km = 0.0;
    for (var i = 1; i < points.length; i++) {
      km += _distanceKm(points[i - 1], points[i]);
    }
    km = (km * 1.3).clamp(1, 200).toDouble();
    final rate = request.body['pricePerKm'] as num;
    final roundTrip = request.body['tripType'] == 'roundTrip' ? 2 : 1;
    const baseFare = 500;
    final distanceFare = (km * rate / 10).round() * 10 * roundTrip;
    const boost = 500;
    final total = baseFare + distanceFare + boost;
    return {
      'baseFare': baseFare,
      'distanceKm': double.parse((km * roundTrip).toStringAsFixed(1)),
      'distanceFare': distanceFare,
      'discount': 0,
      'boost': boost,
      'total': total,
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
