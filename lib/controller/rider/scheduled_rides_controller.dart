import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';

class ScheduledRidesController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ScheduledRidesState> _state = Rx<ScheduledRidesState>(const ScheduledLoading());

  ScheduledRidesState get state => _state.value;

  Future<void> load() async {
    if (state is! ScheduledLoaded) _state.value = const ScheduledLoading();
    try {
      final response = await _api.get(BookingEndpoints.scheduledRides, suppressErrorToast: true);
      final rides = JsonReader.of((response.data as Map)['data'])
          .listOf('rides', ScheduledRide.fromJson, onSkip: (key, error) => log('skipped a scheduled ride: $error'));
      _state.value = ScheduledLoaded(rides);
    } catch (e) {
      log('load scheduled rides failed: $e');
      if (state is! ScheduledLoaded) _state.value = ScheduledFailed(problem: RideLoadProblem.of(e));
    }
  }

  Future<BookingProblem?> cancel(String id) => _act(id, ScheduledAction.cancel, () async {
    await _api.delete(BookingEndpoints.scheduledRideOf(id), suppressErrorToast: true);
    return null;
  });

  Future<BookingProblem?> remind(String id) => _act(id, ScheduledAction.remind, () async {
    final response = await _api.post(
      BookingEndpoints.scheduledRideReminderOf(id),
      key: IdempotencyKey.newFor(IdempotencyIntent.remindRide),
      suppressErrorToast: true,
    );
    return ScheduledRide.fromJson(JsonReader.of((response.data as Map)['data']));
  });

  Future<BookingProblem?> _act(String id, ScheduledAction action, Future<ScheduledRide?> Function() request) async {
    final current = state;
    if (current is! ScheduledLoaded || current.actionOn(id) != null) return null;
    _state.value = current.copyWith(busy: {...current.busy, id: action});
    try {
      final updated = await request();
      _settle(
        id,
        (rides) => [
          for (final ride in rides)
            if (ride.id == id) ?updated else ride,
        ],
      );
      return null;
    } catch (e) {
      log('$action on $id failed: $e');
      final problem = BookingProblem.of(e);
      _settle(
        id,
        (rides) => problem == BookingProblem.notFound
            ? [
                for (final ride in rides)
                  if (ride.id != id) ride,
              ]
            : rides,
      );
      if (e is ApiException && e.outcomeUnknown) unawaited(load());
      return problem;
    }
  }

  void _settle(String id, List<ScheduledRide> Function(List<ScheduledRide>) change) {
    final current = state;
    if (current is! ScheduledLoaded) return;
    _state.value = current.copyWith(rides: change(current.rides), busy: {...current.busy}..remove(id));
  }
}
