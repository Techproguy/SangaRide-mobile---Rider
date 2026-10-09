import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_routes.dart';
import 'package:sanga_ride/core/api/mock/mock_safety.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_wrapup.dart';
import 'package:sanga_ride/core/api/mock/mock_wallet.dart';

abstract final class MockMeState {
  static Object? handle(MockRequest request) {
    final trip = MockTrip.active();
    final rideRequest = MockRoutes.activeRideRequest();
    final sosId = MockSafety.activeSosId;
    return {
      'activeTrip': trip == null ? null : {'id': trip['id'], 'status': trip['status']},
      'tripNeedingPayment': _latestFinishedTrip((id) => !MockTripWrapUp.isSettled(id)),
      'tripNeedingRating': _latestFinishedTrip((id) => MockTripWrapUp.isSettled(id) && !MockTripWrapUp.isRated(id)),
      'activeRideRequest': rideRequest == null ? null : {'id': rideRequest.id, 'status': rideRequest.status},
      'activeSos': sosId == null ? null : {'id': sosId},
      'pendingTopUps': MockWallet.pendingTopUps(),
      'onboarding': {'nextStep': MockAccount.onboardingNextStep},
      'serverTime': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static String? _latestFinishedTrip(bool Function(String id) matches) {
    for (final id in MockTripState.trips.keys.toList().reversed) {
      if (MockTrip.statusOf(id) == 'completed' && matches(id)) return id;
    }
    return null;
  }
}
