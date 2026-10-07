import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

class MockRoutes {
  MockRoutes._();

  static final List<MockRoute> all = [
    MockRoute.post(MockEndpoints.signUp, _signUp),
    MockRoute.post(MockEndpoints.requestOtp, (request) => {'phone': request.body['phone'], 'expiresInSeconds': 300}),
    MockRoute.post(MockEndpoints.verifyOtp, _verifyOtp),
    MockRoute.post(MockEndpoints.googleSignIn, (_) => _session),
    MockRoute.post(MockEndpoints.appleSignIn, (_) => _session),
    MockRoute.post(MockEndpoints.refreshToken, (_) => MockData.tokens),
    MockRoute.post(MockEndpoints.logout, (_) => null),
    MockRoute.get(MockEndpoints.me, (_) => MockData.user),
    MockRoute.patch(MockEndpoints.me, (request) => {...MockData.user, ...request.body}),
    MockRoute.post(MockEndpoints.homeAddress, (request) => request.body),
    MockRoute.post(MockEndpoints.selfie, (_) => {'status': 'verified'}),
  ];

  static Map<String, dynamic> get _session => {'tokens': MockData.tokens, 'user': MockData.user};

  static Object? _signUp(MockRequest request) {
    if (request.body['phone'] == MockData.user['phone']) {
      throw const MockFailure(409, 'This number already has an account.');
    }
    return {'phone': request.body['phone'], 'expiresInSeconds': 300};
  }

  static Object? _verifyOtp(MockRequest request) {
    if (request.body['code'] != MockData.otpCode) {
      throw const MockFailure(400, "That code didn't match. Give it another go.");
    }
    return _session;
  }
}
