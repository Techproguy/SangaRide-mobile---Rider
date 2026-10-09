import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_routes.dart';
import 'package:sanga_ride/core/api/mock/mock_safety.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';

abstract final class MockReset {
  static void clearRideActivity() {
    MockRoutes.resetRideRequests();
    MockTripState.reset();
    MockSafety.reset();
    MockAccount.finishOnboarding();
    MockServer.engine.clearIdempotencyStore();
  }
}
