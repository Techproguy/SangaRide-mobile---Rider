import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_routes.dart';
import 'package:sanga_ride_core/mock.dart';

export 'package:sanga_ride_core/mock.dart' show MockFailure, MockHandler, MockRequest, MockRoute;

abstract final class MockServer {
  static final MockEngine engine = MockEngine(
    routes: () => MockRoutes.all,
    authPathPrefix: '/auth',
    refreshPath: AppEndpoints.refreshToken,
    healthPath: AppEndpoints.health,
  );
}
