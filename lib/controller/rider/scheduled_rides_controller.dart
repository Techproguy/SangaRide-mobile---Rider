import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';

class ScheduledRidesController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<ScheduledRidesState> _state = Rx<ScheduledRidesState>(const ScheduledLoading());

  ScheduledRidesState get state => _state.value;

  Future<void> load() async {
    if (state is! ScheduledLoaded) _state.value = const ScheduledLoading();
    try {
      final response = await _api.get(BookingEndpoints.scheduledRides, suppressErrorToast: true);
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      final rides = [
        for (final json in data['rides'] as List) ScheduledRide.fromJson(Map<String, dynamic>.from(json as Map)),
      ];
      _state.value = ScheduledLoaded(rides);
    } catch (e) {
      log('load scheduled rides failed: $e');
      if (state is! ScheduledLoaded) _state.value = const ScheduledFailed();
    }
  }

  Future<BookingProblem?> cancel(String id) => _act(id, ScheduledAction.cancel, () async {
    await _api.delete(BookingEndpoints.scheduledRideOf(id), options: Options(extra: {'suppressErrorToast': true}));
    return null;
  });

  Future<BookingProblem?> remind(String id) => _act(id, ScheduledAction.remind, () async {
    final response = await _api.post(BookingEndpoints.scheduledRideReminderOf(id), suppressErrorToast: true);
    final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
    return ScheduledRide.fromJson(data);
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
    } on ApiException catch (e) {
      log('$action on $id failed: $e');
      final problem = BookingProblem.fromCode(e.code);
      _settle(
        id,
        (rides) => problem == BookingProblem.notFound
            ? [
                for (final ride in rides)
                  if (ride.id != id) ride,
              ]
            : rides,
      );
      return problem;
    } catch (e) {
      log('$action on $id failed: $e');
      _settle(id, (rides) => rides);
      return BookingProblem.unknown;
    }
  }

  void _settle(String id, List<ScheduledRide> Function(List<ScheduledRide>) change) {
    final current = state;
    if (current is! ScheduledLoaded) return;
    _state.value = current.copyWith(rides: change(current.rides), busy: {...current.busy}..remove(id));
  }
}
