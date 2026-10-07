import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

class MockRoutes {
  MockRoutes._();

  static final List<MockRoute> all = [
    MockRoute.post(MockEndpoints.requestOtp, (request) => {'phone': request.body['phone'], 'expiresInSeconds': 60}),
    MockRoute.post(MockEndpoints.verifyOtp, _verifyOtp),
    MockRoute.post(MockEndpoints.refreshToken, (_) => MockData.tokens),
    MockRoute.post(MockEndpoints.logout, (_) => null),
    MockRoute.get(MockEndpoints.me, (_) => MockData.user),
    MockRoute.patch(MockEndpoints.me, (request) => {...MockData.user, ...request.body}),
  ];

  static Object? _verifyOtp(MockRequest request) {
    if (request.body['code'] != MockData.otpCode) {
      throw const MockFailure(400, "That code didn't match. Give it another go.");
    }
    return {'tokens': MockData.tokens, 'user': MockData.user};
  }
}
