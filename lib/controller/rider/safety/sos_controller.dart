import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/safety/safety_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';

class SosController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 5);
  static const Duration locationWait = Duration(seconds: 4);

  final _api = Get.find<ApiService>();
  final _location = LocationService();

  final Rx<SosState> _state = Rx<SosState>(const SosIdle());
  Timer? _poller;
  String? _tripId;
  LatLng? _coordinates;
  Future<LatLng?>? _pendingLocation;
  int _epoch = 0;
  bool _isPolling = false;

  Rx<SosState> get stateRx => _state;

  SosState get state => _state.value;

  bool get isIdle => state is SosIdle;

  @override
  void onClose() {
    _stopPolling();
    super.onClose();
  }

  void start({required String? tripId}) {
    if (!isIdle) return;
    _tripId = tripId;
    _coordinates = null;
    _epoch++;
    _pendingLocation = _locate();
    _state.value = SosActivating(DateTime.now());
  }

  void cancel() {
    if (state is! SosActivating) return;
    _epoch++;
    _pendingLocation = null;
    _state.value = const SosIdle();
  }

  void resume(Sos sos) {
    if (!isIdle || sos.isEnded) return;
    _epoch++;
    _activate(sos);
  }

  void dismissFailure() {
    if (state is! SosFailed) return;
    _epoch++;
    _state.value = const SosIdle();
  }

  Future<void> send() async {
    if (state is! SosActivating) return;
    final epoch = _epoch;
    unawaited(HapticFeedback.heavyImpact());
    _state.value = const SosSending();
    _coordinates = await _pendingLocation;
    if (epoch != _epoch) return;
    await _post(epoch);
  }

  Future<void> retry() async {
    if (state is! SosFailed) return;
    final epoch = _epoch;
    _state.value = const SosSending();
    await _post(epoch);
  }

  Future<bool> end() async {
    final current = state;
    if (current is! SosActive) return false;
    final epoch = ++_epoch;
    _stopPolling();
    _state.value = SosEnding(current.sos);
    try {
      await _api.post(SafetyEndpoints.sosEndOf(current.sos.id), suppressErrorToast: true);
      if (epoch != _epoch) return false;
      _state.value = const SosIdle();
      return true;
    } catch (e) {
      log('end sos failed: $e');
      if (epoch != _epoch) return false;
      _state.value = SosActive(current.sos);
      _startPolling();
      Toast.error(safetyProblemOf(e).message);
      return false;
    }
  }

  Future<LatLng?> _locate() async {
    try {
      return await _location.getCurrentLocation().timeout(locationWait, onTimeout: () => null);
    } catch (e) {
      log('sos location failed: $e');
      return null;
    }
  }

  Future<void> _post(int epoch) async {
    final coordinates = _coordinates;
    try {
      final response = await _api.post(
        SafetyEndpoints.sos,
        data: {
          'tripId': _tripId,
          if (coordinates != null) 'lat': coordinates.latitude,
          if (coordinates != null) 'lng': coordinates.longitude,
        },
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      _activate(Sos.fromJson(safetyDataOf(response.data)));
    } catch (e) {
      log('send sos failed: $e');
      if (epoch != _epoch) return;
      final running = _runningSosOf(e);
      if (running != null) return _activate(running);
      final problem = safetyProblemOf(e);
      if (problem == SafetyProblem.locationUnavailable) _coordinates = null;
      _state.value = SosFailed(problem);
    }
  }

  Sos? _runningSosOf(Object error) {
    if (error is! ApiException || SafetyProblem.fromCode(error.code) != SafetyProblem.sosAlreadyActive) return null;
    final sos = error.data['sos'];
    return sos is Map
        ? Sos.fromJson({'serverTime': error.data['serverTime'], ...Map<String, dynamic>.from(sos)})
        : null;
  }

  void _activate(Sos sos) {
    _state.value = SosActive(sos);
    _startPolling();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    final current = state;
    if (current is! SosActive || _isPolling) return;
    _isPolling = true;
    final epoch = _epoch;
    try {
      final response = await _api.get(SafetyEndpoints.sosOf(current.sos.id), suppressErrorToast: true);
      if (epoch != _epoch || state is! SosActive) return;
      final sos = Sos.fromJson(safetyDataOf(response.data));
      if (sos.isEnded) {
        _epoch++;
        _stopPolling();
        _state.value = const SosIdle();
      } else {
        _state.value = SosActive(sos);
      }
    } catch (e) {
      log('sos poll failed: $e');
    } finally {
      if (epoch == _epoch) _isPolling = false;
    }
  }
}
