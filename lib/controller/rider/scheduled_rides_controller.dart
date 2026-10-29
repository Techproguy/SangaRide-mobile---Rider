import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';

class ScheduledRidesController extends GetxController {
  static const String _scheduledStatus = 'scheduled';

  final _api = Get.find<ApiService>();

  final Rx<ScheduledRidesState> _state = Rx<ScheduledRidesState>(const ScheduledLoading());

  ScheduledRidesState get state => _state.value;

  Future<void> load() async {
    if (state is! ScheduledLoaded) _state.value = const ScheduledLoading();
    try {
      final response = await _api.get(
        HistoryEndpoints.rides,
        queryParameters: {'status': _scheduledStatus},
        suppressErrorToast: true,
      );
      final rides = JsonReader.of((response.data as Map)['data'])
          .listOf('rides', ScheduledRide.fromRide, onSkip: (key, error) => log('skipped a scheduled ride: $error'));
      final series = await _loadSeries();
      _state.value = ScheduledLoaded([...rides, ...series]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
    } catch (e) {
      log('load scheduled rides failed: $e');
      if (state is! ScheduledLoaded) _state.value = ScheduledFailed(problem: RideLoadProblem.of(e));
    }
  }

  Future<List<ScheduledRide>> _loadSeries() async {
    try {
      final response = await _api.get(BookingEndpoints.series, suppressErrorToast: true);
      final data = (response.data as Map)['data'];
      final items = data is List ? data : (data is Map ? data['series'] : null);
      return [
        for (final item in items is List ? items : const [])
          if (item is Map) ?_parseSeries(item),
      ];
    } catch (e) {
      log('load repeat series failed: $e');
      return const [];
    }
  }

  ScheduledRide? _parseSeries(Map item) {
    try {
      return ScheduledRide.fromSeries(JsonReader.of(item));
    } catch (e) {
      log('skipped a repeat series: $e');
      return null;
    }
  }

  Future<BookingProblem?> cancel(String id) => _act(id, ScheduledAction.cancel, () async {
    final key = IdempotencyKey.newFor(IdempotencyIntent.cancelScheduledRide);
    if (_rideOf(id)?.isRepeat ?? false) {
      await _api.delete(BookingEndpoints.seriesOf(id), key: key, suppressErrorToast: true);
    } else {
      await _api.post(
        BookingEndpoints.scheduledRideCancelOf(id),
        data: const <String, dynamic>{},
        key: key,
        suppressErrorToast: true,
      );
    }
    return null;
  });

  Future<BookingProblem?> editSchedule(String id, RepeatRule rule) => _act(id, ScheduledAction.edit, () async {
    final ride = _rideOf(id);
    if (ride == null) return null;
    await _api.patch(
      BookingEndpoints.seriesOf(id),
      data: rule.toJson(),
      key: IdempotencyKey.newFor(IdempotencyIntent.editSeries),
      suppressErrorToast: true,
    );
    return ride.copyWith(repeat: rule, scheduledAt: rule.firstRideAfter(BookingClock.now()));
  });

  Future<BookingProblem?> remind(String id) => _act(id, ScheduledAction.remind, () async {
    final response = await _api.post(
      BookingEndpoints.scheduledRideReminderOf(id),
      key: IdempotencyKey.newFor(IdempotencyIntent.remindRide),
      suppressErrorToast: true,
    );
    final ride = _rideOf(id);
    if (ride == null) return null;
    final reply = (response.data as Map)['data'];
    final replied = reply is Map ? JsonReader.of(reply).timeOrNull('reminderAt')?.toLocal() : null;
    return ride.copyWith(reminderAt: replied);
  });

  ScheduledRide? _rideOf(String id) {
    final current = state;
    return current is ScheduledLoaded ? current.rides.where((ride) => ride.id == id).firstOrNull : null;
  }

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
