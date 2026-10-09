import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/core/api/airport_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class FlightTrackingController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 30);
  static const String alreadyNotifiedCode = 'already_notified';

  final _api = Get.find<ApiService>();

  final Rx<FlightTrackingState> _state = Rx<FlightTrackingState>(const FlightTrackingLoading());
  final Rx<DriverNotifyState> _notify = Rx<DriverNotifyState>(const NotifyIdle());

  LivePoller? _poller;
  Mutation<DateTime>? _notifyMutation;
  String? _rideId;
  int _epoch = 0;

  FlightTrackingState get state => _state.value;

  DriverNotifyState get notifyState => _notify.value;

  FlightTracking? get tracking => switch (state) {
    FlightTrackingReady(:final tracking) => tracking,
    _ => null,
  };

  @override
  void onClose() {
    close();
    super.onClose();
  }

  Future<void> open(String rideId) async {
    if (_rideId == rideId) return;
    close();
    _rideId = rideId;
    final epoch = ++_epoch;
    _state.value = const FlightTrackingLoading();
    final poller = LivePoller(fetch: () => _fetch(epoch), interval: pollInterval);
    _poller = poller;
    poller.start();
  }

  void close() {
    _poller?.dispose();
    _poller = null;
    _notifyMutation?.dispose();
    _notifyMutation = null;
    _rideId = null;
    _epoch++;
    _state.value = const FlightTrackingLoading();
    _notify.value = const NotifyIdle();
  }

  Future<void> retry() async {
    if (_rideId == null || state is! FlightTrackingFailed) return;
    _state.value = const FlightTrackingLoading();
    await _poller?.refreshNow();
  }

  Future<void> reload() async {
    final current = state;
    if (_rideId == null || current is FlightTrackingLoading) return;
    await _poller?.refreshNow();
  }

  Future<void> _fetch(int epoch) async {
    final id = _rideId;
    if (id == null || epoch != _epoch) return;
    try {
      final response = await _api.get(AirportEndpoints.rideFlightOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final data = JsonReader.of(JsonReader.of(response.data).raw['data']).raw;
      _state.value = FlightTrackingReady(FlightTracking.fromJson(data));
    } catch (e) {
      log('flight tracking failed: $e');
      if (epoch != _epoch) return;
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 410)) {
        _poller?.stop();
        _state.value = const FlightTrackingFailed(FlightTrackingFailure.notFound);
        return;
      }
      if (state is! FlightTrackingReady) _state.value = const FlightTrackingFailed(FlightTrackingFailure.connection);
      rethrow;
    }
  }

  Future<BookingProblem?> notifyDriver() async {
    final id = _rideId;
    if (id == null || notifyState is NotifySending) return null;
    if (LiveProblem.isOffline) return BookingProblem.connection;
    final epoch = _epoch;
    _notify.value = const NotifySending();
    final mutation = _notifyMutation ??= Mutation<DateTime>(
      intent: 'flight-notify',
      run: (key) async {
        final response = await _api.post(AirportEndpoints.notifyDriverOf(id), key: key, suppressErrorToast: true);
        final data = JsonReader.of(JsonReader.of(response.data).raw['data']);
        return (data.timeOrNull('notifiedAt') ?? DateTime.now()).toLocal();
      },
    );
    final result = await mutation.start();
    if (epoch != _epoch) return null;
    switch (result) {
      case MutationDone<DateTime>(:final value):
        _notifyMutation?.dispose();
        _notifyMutation = null;
        _notify.value = NotifySent(value);
        return null;
      case MutationRejected<DateTime>(:final error):
        _notifyMutation?.dispose();
        _notifyMutation = null;
        if (error.code == alreadyNotifiedCode) {
          _notify.value = NotifySent(DateTime.now());
          return null;
        }
        _notify.value = const NotifyIdle();
        unawaited(_poller?.refreshNow());
        return BookingProblem.of(error);
      case MutationFailed<DateTime>(:final error) || MutationUnknown<DateTime>(:final error):
        _notify.value = const NotifyIdle();
        return BookingProblem.of(error);
      default:
        _notify.value = const NotifyIdle();
        return null;
    }
  }
}
