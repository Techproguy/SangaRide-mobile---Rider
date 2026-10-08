import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideMatchController extends GetxController {
  static const Duration pollInterval = Duration(milliseconds: 1500);
  static const Duration autoContinueAfter = Duration(seconds: 5);
  static const Duration rowExitDuration = SangaMotion.morph;
  static const int maxMissedPolls = 3;
  static const String genericFailure = 'We couldn’t reach the server. Give it another go.';

  final _api = Get.find<ApiService>();
  final _trip = Get.find<RideRequestController>();

  final Rx<RideMatchState> _state = Rx<RideMatchState>(const MatchIdle());
  Timer? _poller;
  String? _requestId;
  int _epoch = 0;
  int _missedPolls = 0;
  bool _isPolling = false;

  Rx<RideMatchState> get stateRx => _state;

  RideMatchState get state => _state.value;

  bool get isStarting => state is MatchStarting;

  bool get isLive => switch (state) {
    MatchStarting() ||
    MatchSearching() ||
    MatchOffersReady() ||
    MatchOffersLoading() ||
    MatchOffersFailed() ||
    MatchBrowsing() => true,
    MatchIdle() ||
    MatchNoDriver() ||
    MatchCancelled() ||
    MatchFailed() ||
    MatchConfirmed() ||
    MatchScheduled() => false,
  };

  DriverHold? get holding => switch (state) {
    MatchHolding(:final hold) => hold,
    _ => null,
  };

  @override
  void onClose() {
    _invalidate();
    super.onClose();
  }

  int _invalidate() {
    _poller?.cancel();
    _poller = null;
    _isPolling = false;
    return ++_epoch;
  }

  Map<String, dynamic>? _payload() => _trip.requestPayload();

  Future<void> requestRide() async {
    if (isLive) return;
    final payload = _payload();
    if (payload == null) {
      _state.value = const MatchFailed(MatchFailure.couldNotStart);
      return;
    }
    final epoch = _invalidate();
    _requestId = null;
    _missedPolls = 0;
    _state.value = const MatchStarting();
    try {
      final response = await _api.post(MockEndpoints.rideRequests, data: payload, suppressErrorToast: true);
      final data = _dataOf(response.data);
      if (data['status'] == 'scheduled') {
        if (epoch == _epoch) _state.value = MatchScheduled(ScheduledBooking.fromJson(data));
        return;
      }
      final request = MatchRequest.fromJson(data);
      if (epoch != _epoch) {
        unawaited(_sendCancel(request.id));
        return;
      }
      _requestId = request.id;
      _applyRequest(request);
    } on ApiException catch (e) {
      log('requestRide failed: $e');
      if (epoch == _epoch) _state.value = MatchFailed(MatchFailure.couldNotStart, code: e.code, data: e.data);
    } catch (e) {
      log('requestRide failed: $e');
      if (epoch == _epoch) _state.value = const MatchFailed(MatchFailure.couldNotStart);
    }
  }

  Future<ScheduledBooking?> scheduleRide() async {
    if (isLive) return null;
    final payload = _payload();
    final scheduledAt = _trip.scheduledAt;
    if (payload == null || scheduledAt == null) return null;
    _state.value = const MatchStarting();
    try {
      final response = await _api.post(
        MockEndpoints.rideRequestsScheduled,
        data: {...payload, 'scheduledAt': scheduledAt.toUtc().toIso8601String()},
      );
      return ScheduledBooking.fromJson(_dataOf(response.data));
    } catch (e) {
      log('scheduleRide failed: $e');
      return null;
    } finally {
      _state.value = const MatchIdle();
    }
  }

  Future<void> retry() async {
    if (isStarting) return;
    if (isLive && !await cancelRequest()) return;
    await requestRide();
  }

  Future<bool> cancelRequest() async {
    final id = _requestId;
    if (id == null) return false;
    final epoch = _invalidate();
    try {
      await _api.post(MockEndpoints.rideRequestCancelOf(id));
    } catch (e) {
      log('cancelRequest failed: $e');
      if (epoch == _epoch && state is MatchSearching) _startPolling();
      return false;
    }
    if (epoch != _epoch) return false;
    _requestId = null;
    _state.value = const MatchCancelled();
    return true;
  }

  void abandon() {
    final id = _requestId;
    if (!isLive) return;
    _invalidate();
    _requestId = null;
    _state.value = const MatchCancelled();
    if (id != null) unawaited(_sendCancel(id));
  }

  Future<void> _sendCancel(String id) async {
    try {
      await _api.post(MockEndpoints.rideRequestCancelOf(id), suppressErrorToast: true);
    } catch (e) {
      log('cancel of $id failed: $e');
    }
  }

  void _applyRequest(MatchRequest request) {
    if (state is! MatchStarting && state is! MatchSearching) return;
    if (request.hasSearchExpired) {
      _finishSearch(const MatchNoDriver());
      return;
    }
    switch (request.status) {
      case RideRequestStatus.searching || RideRequestStatus.checking || RideRequestStatus.sending:
        _state.value = MatchSearching(request);
        if (_poller == null) _startPolling();
      case RideRequestStatus.offers:
        _finishSearch(MatchOffersReady(request: request, continueAt: DateTime.now().add(autoContinueAfter)));
      case RideRequestStatus.noDriverFound:
        _finishSearch(const MatchNoDriver());
      case RideRequestStatus.cancelled:
        _finishSearch(const MatchCancelled());
    }
  }

  void _finishSearch(RideMatchState next) {
    _poller?.cancel();
    _poller = null;
    if (next is MatchNoDriver || next is MatchCancelled) _requestId = null;
    _state.value = next;
  }

  void _startPolling() {
    _poller?.cancel();
    final epoch = _epoch;
    _poller = Timer.periodic(pollInterval, (_) => _poll(epoch));
  }

  Future<void> _poll(int epoch) async {
    final id = _requestId;
    if (_isPolling || id == null || epoch != _epoch || state is! MatchSearching) return;
    _isPolling = true;
    try {
      final response = await _api.get(MockEndpoints.rideRequestOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      _missedPolls = 0;
      _applyRequest(MatchRequest.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('poll failed: $e');
      if (epoch == _epoch && ++_missedPolls >= maxMissedPolls) _loseConnection(id);
    } finally {
      _isPolling = false;
    }
  }

  void _loseConnection(String id) {
    _invalidate();
    _requestId = null;
    _state.value = const MatchFailed(MatchFailure.connectionLost);
    unawaited(_sendCancel(id));
  }

  Future<void> loadOffers() async {
    final id = _requestId;
    if (id == null || (state is! MatchOffersReady && state is! MatchOffersFailed)) return;
    final epoch = _epoch;
    _state.value = const MatchOffersLoading();
    try {
      final response = await _api.get(MockEndpoints.rideRequestOffersOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final offers = _dataOf(response.data)['offers'] as List;
      _state.value = MatchOffersListed([
        for (final json in offers) OfferRow(DriverOffer.fromJson(Map<String, dynamic>.from(json as Map))),
      ]);
    } catch (e) {
      log('loadOffers failed: $e');
      if (epoch == _epoch) _state.value = const MatchOffersFailed();
    }
  }

  Future<void> ignore(DriverOffer offer) async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchOffersListed || current.acceptingOfferId != null) return;
    if (current.rows.any((row) => row.offer.id == offer.id && row.isLeaving)) return;
    final epoch = _epoch;
    _state.value = current.withRows([for (final row in current.rows) row.offer.id == offer.id ? row.asLeaving() : row]);
    unawaited(_sendIgnore(id, offer.id));
    await Future<void>.delayed(rowExitDuration);
    final latest = state;
    if (epoch != _epoch || latest is! MatchBrowsing) return;
    _state.value = latest.withRows([
      for (final row in latest.rows)
        if (row.offer.id != offer.id) row,
    ]);
  }

  Future<void> _sendIgnore(String id, String offerId) async {
    try {
      await _api.post(MockEndpoints.rideOfferIgnoreOf(id, offerId), suppressErrorToast: true);
    } catch (e) {
      log('ignore failed: $e');
    }
  }

  Future<bool> hold(DriverOffer offer) async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchOffersListed || current.acceptingOfferId != null || !offer.isAvailable) {
      return false;
    }
    final epoch = _epoch;
    _state.value = MatchOffersListed(current.rows, acceptingOfferId: offer.id);
    try {
      final response = await _api.post(MockEndpoints.rideOfferHoldOf(id, offer.id), suppressErrorToast: true);
      if (epoch != _epoch) return false;
      _state.value = MatchHolding(current.rows, hold: DriverHold.fromJson(_dataOf(response.data)));
      return true;
    } catch (e) {
      log('hold failed: $e');
      if (epoch == _epoch) _backToOffers(e, offer.id);
      return false;
    }
  }

  Future<void> releaseHold() async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchHolding || current.isConfirming) return;
    _state.value = MatchOffersListed(current.rows);
    try {
      await _api.delete(MockEndpoints.rideRequestHoldOf(id));
    } catch (e) {
      log('releaseHold failed: $e');
    }
  }

  Future<void> expireHold() async {
    if (state is! MatchHolding) return;
    Toast.warning(OfferUnavailableReason.holdExpired.message);
    await releaseHold();
  }

  Future<bool> confirm() async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchHolding || current.isConfirming) return false;
    final epoch = _epoch;
    _state.value = MatchHolding(current.rows, hold: current.hold, isConfirming: true);
    try {
      final response = await _api.post(
        MockEndpoints.rideOfferConfirmOf(id, current.hold.offerId),
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return false;
      _requestId = null;
      _state.value = MatchConfirmed(ConfirmedTrip.fromJson(_dataOf(response.data)));
      return true;
    } catch (e) {
      log('confirm failed: $e');
      if (epoch != _epoch) return false;
      final reason = _reasonOf(e);
      if (reason == null) {
        _state.value = MatchHolding(current.rows, hold: current.hold);
        Toast.error(genericFailure);
      } else {
        _backToOffers(e, current.hold.offerId);
      }
      return false;
    }
  }

  void _backToOffers(Object error, String offerId) {
    final current = state;
    if (current is! MatchBrowsing) return;
    final reason = _reasonOf(error);
    final removesOffer = reason?.removesOffer ?? false;
    _state.value = MatchOffersListed([
      for (final row in current.rows) removesOffer && row.offer.id == offerId ? row.asWithdrawn() : row,
    ]);
    Toast.error(reason?.message ?? genericFailure);
  }

  OfferUnavailableReason? _reasonOf(Object error) {
    if (error is! ApiException || error.code == null) return null;
    return OfferUnavailableReason.fromCode(error.code);
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
