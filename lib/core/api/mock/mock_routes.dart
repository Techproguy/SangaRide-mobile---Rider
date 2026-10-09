import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_booking.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_groups.dart';
import 'package:sanga_ride/core/api/mock/mock_who_for.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_me_state.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_safety.dart';
import 'package:sanga_ride/core/api/mock/mock_notifications.dart';
import 'package:sanga_ride/core/api/mock/mock_ride_requests.dart';
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
    ...MockRideRequests.routes,
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
    ...MockGroups.routes,
    MockRoute.get(AppEndpoints.meState, MockMeState.handle),
    MockRoute.post(AppEndpoints.signUp, _signUp),
    MockRoute.post(
      AppEndpoints.checkExistence,
      (request) => {'exists': request.body['phone'] == MockData.user['phone']},
    ),
    MockRoute.post(AppEndpoints.requestOtp, _requestOtp),
    MockRoute.post(AppEndpoints.verifyOtp, _verifyOtp),
    MockRoute.post(AppEndpoints.googleSignIn, (_) => _session),
    MockRoute.post(AppEndpoints.appleSignIn, (_) => _session),
    MockRoute.post(AppEndpoints.logout, (request) {
      MockServer.engine.revoke(request);
      return null;
    }),
    MockRoute.post(VerificationEndpoints.selfie, _selfie),
    MockRoute.get(AppEndpoints.recentPlaces, (_) => _recentPlaces),
    MockRoute.post(AppEndpoints.recentPlaces, _addRecentPlace),
    MockRoute.delete(AppEndpoints.recentPlace, (request) {
      _recentPlaces.removeWhere((place) => place['place_id'] == request.params['id']);
      return null;
    }),
    MockRoute.get(AppEndpoints.weather, (_) => MockData.weather),
  ];


  static void resetRideRequests() => MockRideRequests.reset();

  static ({String id, String status})? activeRideRequest() => MockRideRequests.activeRideRequest();

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

  static Map<String, dynamic> get _session => {'tokens': MockServer.engine.issueTokens(), 'user': MockData.user};

  static Object? _signUp(MockRequest request) {
    MockAccount.beginOnboarding();
    return {'phone': request.body['phone'], 'expiresInSeconds': 300, 'resendInSeconds': 60};
  }

  static Object? _selfie(MockRequest request) {
    final result = MockVerification.selfie(request);
    MockAccount.completeOnboardingStep(MockOnboardingStep.selfie);
    return result;
  }

  static Object? _requestOtp(MockRequest request) {
    final isLogin = request.body['purpose'] == 'login';
    if (isLogin) MockAccount.finishOnboarding();
    if (isLogin && request.body['phone'] == MockData.unregisteredPhone) {
      throw const MockFailure(404, 'We can’t find an account with this number.');
    }
    return {'phone': request.body['phone'], 'expiresInSeconds': 300, 'resendInSeconds': 60};
  }

  static Object? _verifyOtp(MockRequest request) {
    if (request.body['code'] != MockData.otpCode) {
      throw const MockFailure(400, "That code didn't match. Give it another go.");
    }
    MockAccount.cancelDeletion();
    return _session;
  }
}
