import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SessionRestore extends GetxService {
  SessionRestore(this._api);

  static const Duration bootCap = Duration(seconds: 4);
  static const Duration quietCap = Duration(seconds: 8);
  static const Duration staleAfter = Duration(seconds: 5);

  final ApiService _api;

  final Rxn<MeState> _meState = Rxn<MeState>();
  final RxBool _restoreFailed = false.obs;
  final RxBool _isRestoring = false.obs;
  final RxnString _pendingRideRequestId = RxnString();

  StreamSubscription<void>? _resumeSubscription;
  ConnectionMonitor? _watchedMonitor;
  CancelToken? _cancelToken;
  Future<MeState?>? _inFlight;
  ConnectionStatus _lastStatus = ConnectionStatus.online;
  DateTime? _lastAppliedAt;

  Rxn<MeState> get meStateRx => _meState;

  MeState? get meState => _meState.value;

  bool get restoreFailed => _restoreFailed.value;

  bool get isRestoring => _isRestoring.value;

  String? get pendingRideRequestId => _pendingRideRequestId.value;

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => unawaited(refreshQuietly()));
    _watchedMonitor = ConnectionMonitor.current;
    _watchedMonitor?.status.addListener(_onConnectionChanged);
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _watchedMonitor?.status.removeListener(_onConnectionChanged);
    _cancelToken?.cancel();
    super.onClose();
  }

  Future<List<String>> resolveBoot() async {
    _isRestoring.value = true;
    unawaited(Get.find<UserController>().fetchMe());
    try {
      final state = await _fetch(bootCap);
      if (state == null) {
        _restoreFailed.value = true;
        return const [SangaRoutes.home];
      }
      return _stackFor(state);
    } finally {
      _isRestoring.value = false;
    }
  }

  Future<List<String>?> retry() async {
    _isRestoring.value = true;
    try {
      final state = await _fetch(bootCap);
      return state == null ? null : _stackFor(state);
    } finally {
      _isRestoring.value = false;
    }
  }

  Future<void> refreshQuietly() async {
    if (!SessionStorage.tokens.hasSession) return;
    await _fetch(quietCap);
  }

  Future<void> refreshIfStale() async {
    final appliedAt = _lastAppliedAt;
    if (appliedAt != null && DateTime.now().difference(appliedAt) < staleAfter) return;
    await refreshQuietly();
  }

  Future<void> open(List<String> stack) async {
    if (stack.isEmpty) return;
    SangaRouter.router.go(stack.first);
    for (final route in stack.skip(1)) {
      await WidgetsBinding.instance.endOfFrame;
      unawaited(SangaRouter.router.push<Object?>(route));
    }
  }

  void reset() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _inFlight = null;
    _lastAppliedAt = null;
    _meState.value = null;
    _restoreFailed.value = false;
    _isRestoring.value = false;
    _pendingRideRequestId.value = null;
  }

  void _onConnectionChanged() {
    final status = _watchedMonitor?.status.value ?? ConnectionStatus.online;
    final recovered = status == ConnectionStatus.online && _lastStatus != ConnectionStatus.online;
    _lastStatus = status;
    if (recovered) unawaited(refreshQuietly());
  }

  Future<MeState?> _fetch(Duration cap) {
    if (!SessionStorage.tokens.hasSession) return Future.value();
    return _inFlight ??= _run(cap).whenComplete(() => _inFlight = null);
  }

  Future<MeState?> _run(Duration cap) async {
    final token = _cancelToken = CancelToken();
    final state = await _request(token).timeout(
      cap,
      onTimeout: () {
        token.cancel();
        return null;
      },
    );
    if (state != null && identical(_cancelToken, token)) _apply(state);
    return state;
  }

  Future<MeState?> _request(CancelToken token) async {
    try {
      final response = await _api.client.get(
        AppEndpoints.meState,
        cancelToken: token,
        profile: RequestProfile.interactive,
      );
      return MeState.fromEnvelope(response.data);
    } catch (error) {
      log('me state failed: ${error is ApiException ? error.kind : error.runtimeType}');
      return null;
    }
  }

  void _apply(MeState state) {
    _lastAppliedAt = DateTime.now();
    _meState.value = state;
    _restoreFailed.value = false;
    _pendingRideRequestId.value = state.activeRideRequest?.id;
  }

  List<String> _stackFor(MeState state) {
    final step = state.onboardingStep;
    if (step != null) return [_onboardingRoute(step)];
    if (state.activeSosId != null) return [SangaRoutes.home, SafetyRoutes.centreOf(tripId: state.activeTrip?.id)];
    final trip = state.activeTrip;
    if (trip != null) return [SangaRoutes.home, TripRoutes.tripOf(trip.id)];
    if (state.activeRideRequest != null) return const [SangaRoutes.home, SangaRoutes.rideOffers];
    final unpaid = state.tripNeedingPayment;
    if (unpaid != null) return [SangaRoutes.home, TripWrapUpRoutes.payOf(unpaid)];
    final unrated = state.tripNeedingRating;
    if (unrated != null) return [SangaRoutes.home, TripWrapUpRoutes.rateOf(unrated)];
    return const [SangaRoutes.home];
  }

  String _onboardingRoute(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.aboutYou => SangaRoutes.aboutYou,
      OnboardingStep.selfie => SangaRoutes.selfie,
      OnboardingStep.homePlace => SangaRoutes.homeLocation,
    };
  }
}
