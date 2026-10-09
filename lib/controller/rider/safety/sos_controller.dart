import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/core/safety_config.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SosController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 5);
  static const Duration locationWait = Duration(seconds: 4);

  final _api = Get.find<ApiService>();
  final _location = LocationService();

  final Rx<SosState> _state = Rx<SosState>(const SosIdle());
  final RxInt _contactCount = 0.obs;
  final Rx<Duration> _grace = Rx<Duration>(SafetyConfig.sosGrace);
  final RxString _emergencyNumber = SafetyConfig.emergencyNumber.obs;
  LivePoller? _poller;
  Worker? _meWorker;
  Timer? _graceTimer;
  Mutation<Sos>? _sendMutation;
  IdempotencyKey? _endKey;
  String? _tripId;
  LatLng? _coordinates;
  Future<LatLng?>? _pendingLocation;
  final Epoch _epoch = Epoch();

  Rx<SosState> get stateRx => _state;

  SosState get state => _state.value;

  bool get isIdle => state is SosIdle;

  int get contactCount => _contactCount.value;

  Duration get grace => _grace.value;

  String get emergencyNumber => _emergencyNumber.value;

  @override
  void onInit() {
    super.onInit();
    final restore = Get.find<SessionRestore>();
    _meWorker = ever(restore.meStateRx, (_) => unawaited(_resumeFromState()));
    unawaited(_resumeFromState());
  }

  @override
  void onClose() {
    _meWorker?.dispose();
    _graceTimer?.cancel();
    _sendMutation?.dispose();
    _stopPolling();
    super.onClose();
  }

  void learnFrom(SafetyCentre centre) {
    _contactCount.value = centre.contacts.length;
    _grace.value = centre.sosGrace;
    _emergencyNumber.value = centre.emergencyNumber;
  }

  Future<void> _resumeFromState() async {
    final id = Get.find<SessionRestore>().meState?.activeSosId;
    if (id == null || !isIdle) return;
    final epoch = _epoch.next();
    try {
      final response = await _api.get(SafetyEndpoints.sosOf(id), suppressErrorToast: true);
      if (!_epoch.isCurrent(epoch) || !isIdle) return;
      final sos = Sos.fromJson(response.dataMapOrEmpty);
      if (!sos.isEnded) _activate(sos);
    } catch (e) {
      log('sos resume failed: $e');
    }
  }

  void start({required String? tripId}) {
    if (!isIdle) return;
    _tripId = tripId;
    _coordinates = null;
    _epoch.next();
    _sendMutation?.dispose();
    _sendMutation = null;
    _pendingLocation = _locate();
    _state.value = SosActivating(DateTime.now());
    _graceTimer?.cancel();
    _graceTimer = Timer(grace, () => unawaited(send()));
  }

  void cancel() {
    if (state is! SosActivating) return;
    _epoch.next();
    _graceTimer?.cancel();
    _pendingLocation = null;
    _state.value = const SosIdle();
  }

  void resume(Sos sos) {
    if (!isIdle || sos.isEnded) return;
    _epoch.next();
    _activate(sos);
  }

  void dismissFailure() {
    if (state is! SosFailed) return;
    _epoch.next();
    _sendMutation?.dispose();
    _sendMutation = null;
    _state.value = const SosIdle();
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }

  Future<void> send() async {
    if (state is! SosActivating) return;
    _graceTimer?.cancel();
    final epoch = _epoch.current;
    unawaited(HapticFeedback.heavyImpact());
    _state.value = const SosSending();
    _coordinates = await _pendingLocation;
    if (!_epoch.isCurrent(epoch)) return;
    await _post(epoch);
  }

  Future<void> retry() async {
    if (state is! SosFailed) return;
    final epoch = _epoch.current;
    _state.value = const SosSending();
    await _post(epoch);
  }

  Future<bool> end() async {
    final current = state;
    if (current is! SosActive) return false;
    final epoch = _epoch.next();
    _stopPolling();
    _state.value = SosEnding(current.sos);
    try {
      await _api.post(
        SafetyEndpoints.sosEndOf(current.sos.id),
        key: _endKey ??= IdempotencyKey.newFor(IdempotencyIntent.sosEnd),
        suppressErrorToast: true,
      );
      if (!_epoch.isCurrent(epoch)) return false;
      _endKey = null;
      _state.value = const SosIdle();
      unawaited(Get.find<SessionRestore>().refreshQuietly());
      return true;
    } catch (e) {
      log('end sos failed: $e');
      if (!_epoch.isCurrent(epoch)) return false;
      _state.value = SosActive(current.sos);
      _startPolling(current.sos.id);
      SangaToast.show(SafetyProblem.of(e).message, tone: SangaToastTone.error);
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
    final tripId = _tripId;
    final mutation = _sendMutation ??= Mutation<Sos>(
      intent: IdempotencyIntent.sos,
      run: (key) async {
        final response = await _api.post(
          SafetyEndpoints.sos,
          data: {
            'tripId': tripId,
            if (coordinates != null) 'lat': coordinates.latitude,
            if (coordinates != null) 'lng': coordinates.longitude,
          },
          key: key,
          suppressErrorToast: true,
        );
        return Sos.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () => _reconcile(tripId),
    );
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return;
    switch (result) {
      case MutationDone<Sos>(:final value):
        _sendMutation?.dispose();
        _sendMutation = null;
        _activate(value);
        unawaited(Get.find<SessionRestore>().refreshQuietly());
      case MutationRejected<Sos>(:final error):
        _sendMutation?.dispose();
        _sendMutation = null;
        _onRejected(error);
      case MutationFailed<Sos>(:final error):
        _state.value = SosFailed(SafetyProblem.of(error));
      case MutationUnknown<Sos>():
        _state.value = const SosFailed(SafetyProblem.unconfirmed);
      default:
        break;
    }
  }

  Future<Reconciled<Sos>> _reconcile(String? tripId) async {
    final response = await _api.get(
      SafetyEndpoints.centre,
      queryParameters: {'tripId': ?tripId},
      suppressErrorToast: true,
      profile: RequestProfile.interactive,
    );
    final active = SafetyCentre.fromJson(response.dataMapOrEmpty).activeSos;
    return active == null ? const ReconciledNotDone() : ReconciledDone(active);
  }

  void _onRejected(ApiException error) {
    final running = _runningSosOf(error);
    if (running != null) {
      _activate(running);
      return;
    }
    final problem = SafetyProblem.of(error);
    if (problem == SafetyProblem.locationUnavailable) _coordinates = null;
    _state.value = SosFailed(problem);
  }

  Sos? _runningSosOf(ApiException error) {
    if (SafetyProblem.fromCode(error.code) != SafetyProblem.sosAlreadyActive) return null;
    final sos = error.data['sos'];
    if (sos is! Map) return null;
    try {
      return Sos.fromJson(Map<String, dynamic>.from(sos));
    } catch (_) {
      return null;
    }
  }

  void _activate(Sos sos) {
    _state.value = SosActive(sos);
    _startPolling(sos.id);
  }

  void _startPolling(String sosId) {
    _stopPolling();
    final epoch = _epoch.current;
    final poller = LivePoller(fetch: () => _poll(sosId, epoch), interval: pollInterval);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    _poller?.dispose();
    _poller = null;
  }

  Future<void> _poll(String sosId, int epoch) async {
    if (state is! SosActive || !_epoch.isCurrent(epoch)) return;
    try {
      final response = await _api.get(SafetyEndpoints.sosOf(sosId), suppressErrorToast: true);
      if (!_epoch.isCurrent(epoch) || state is! SosActive) return;
      final sos = Sos.fromJson(response.dataMapOrEmpty);
      if (sos.isEnded) {
        _finishRemotely();
      } else {
        _state.value = SosActive(sos);
      }
    } catch (e) {
      if (!_epoch.isCurrent(epoch)) return;
      if (e is ApiException && e.isGone) {
        _finishRemotely();
        return;
      }
      rethrow;
    }
  }

  void _finishRemotely() {
    _epoch.next();
    _stopPolling();
    _state.value = const SosIdle();
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }
}
