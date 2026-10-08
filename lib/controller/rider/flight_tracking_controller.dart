import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/airport_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';

class FlightTrackingController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 30);

  final _api = Get.find<ApiService>();

  final Rx<FlightTrackingState> _state = Rx<FlightTrackingState>(const FlightTrackingLoading());
  final Rx<DriverNotifyState> _notify = Rx<DriverNotifyState>(const NotifyIdle());

  AppLifecycleListener? _lifecycle;
  Timer? _poller;
  String? _rideId;
  int _epoch = 0;
  bool _isFetching = false;

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
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    await _fetch(epoch);
    if (epoch == _epoch) _startPolling();
  }

  void close() {
    _poller?.cancel();
    _poller = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _rideId = null;
    _epoch++;
    _isFetching = false;
    _state.value = const FlightTrackingLoading();
    _notify.value = const NotifyIdle();
  }

  Future<void> retry() async {
    if (_rideId == null || state is! FlightTrackingFailed) return;
    _state.value = const FlightTrackingLoading();
    await _fetch(_epoch);
    if (state is FlightTrackingReady) _startPolling();
  }

  Future<void> reload() async {
    final current = state;
    if (_rideId == null || current is FlightTrackingLoading) return;
    await _fetch(_epoch);
  }

  void _onLifecycle(AppLifecycleState lifecycle) {
    if (_rideId == null) return;
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(_fetch(_epoch));
      _startPolling();
    } else {
      _poller?.cancel();
      _poller = null;
    }
  }

  void _startPolling() {
    _poller?.cancel();
    final epoch = _epoch;
    _poller = Timer.periodic(pollInterval, (_) => unawaited(_fetch(epoch, isQuiet: true)));
  }

  Future<void> _fetch(int epoch, {bool isQuiet = false}) async {
    final id = _rideId;
    if (id == null || _isFetching || epoch != _epoch) return;
    _isFetching = true;
    final current = state;
    if (current is FlightTrackingReady && !isQuiet) {
      _state.value = FlightTrackingReady(current.tracking, isRefreshing: true);
    }
    try {
      final response = await _api.get(AirportEndpoints.rideFlightOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _state.value = FlightTrackingReady(FlightTracking.fromJson(data));
    } on ApiException catch (e) {
      log('flight tracking failed: $e');
      if (epoch == _epoch) {
        _failOrKeep(e.statusCode == 404 ? FlightTrackingFailure.notFound : FlightTrackingFailure.connection);
      }
    } catch (e) {
      log('flight tracking failed: $e');
      if (epoch == _epoch) _failOrKeep(FlightTrackingFailure.connection);
    } finally {
      _isFetching = false;
    }
  }

  void _failOrKeep(FlightTrackingFailure reason) {
    final current = state;
    if (current is FlightTrackingReady && reason.canRetry) {
      _state.value = FlightTrackingReady(current.tracking);
      return;
    }
    _poller?.cancel();
    _poller = null;
    _state.value = FlightTrackingFailed(reason);
  }

  Future<BookingProblem?> notifyDriver() async {
    final id = _rideId;
    if (id == null || notifyState is NotifySending) return null;
    final epoch = _epoch;
    _notify.value = const NotifySending();
    try {
      final response = await _api.post(AirportEndpoints.notifyDriverOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return null;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _notify.value = NotifySent(DateTime.parse(data['notifiedAt'] as String).toLocal());
      return null;
    } on ApiException catch (e) {
      log('notifyDriver failed: $e');
      if (epoch == _epoch) {
        _notify.value = const NotifyIdle();
        unawaited(_fetch(epoch, isQuiet: true));
      }
      return BookingProblem.fromCode(e.code);
    } catch (e) {
      log('notifyDriver failed: $e');
      if (epoch == _epoch) _notify.value = const NotifyIdle();
      return BookingProblem.unknown;
    }
  }
}
