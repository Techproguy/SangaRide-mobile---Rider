import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideMatchController extends GetxController {
  static const Duration pollInterval = Duration(milliseconds: 1500);
  static const Duration approvalPollInterval = Duration(seconds: 2);
  static const Duration offersRefreshInterval = Duration(seconds: 5);
  static const Duration autoContinueAfter = Duration(seconds: 5);
  static const Duration rowExitDuration = SangaMotion.morph;
  static const Duration retryDelay = Duration(seconds: 2);
  static const String _sessionName = 'ride_match';
  static const String _draftKey = 'ride_match';
  static const String _cancelsKey = 'pending_ride_cancels';

  final _api = Get.find<ApiService>();
  final _trip = Get.find<RideRequestController>();

  final Rx<RideMatchState> _state = Rx<RideMatchState>(const MatchIdle());
  final Set<String> _pendingCancels = {};

  LivePoller? _searchPoller;
  LivePoller? _approvalPoller;
  LivePoller? _offersPoller;
  Timer? _expiryTimer;
  StreamSubscription<void>? _resumeSubscription;
  ConnectionMonitor? _monitor;
  ConnectionStatus _lastStatus = ConnectionStatus.online;
  Mutation<CreateOutcome>? _create;
  String? _createSignature;
  Mutation<ConfirmedTrip>? _confirmMutation;
  String? _confirmSignature;
  String? _requestId;
  String? _approvalId;
  Map<String, dynamic>? _approvalPayload;
  int _epoch = 0;
  bool _isFlushingCancels = false;

  Rx<RideMatchState> get stateRx => _state;

  RideMatchState get state => _state.value;

  bool get isStarting => state is MatchStarting;

  bool get hasPendingRequest => _requestId != null;

  bool get isLive => switch (state) {
    MatchStarting() ||
    MatchResuming() ||
    MatchSearching() ||
    MatchOffersReady() ||
    MatchOffersLoading() ||
    MatchOffersFailed() ||
    MatchAwaitingApproval() ||
    MatchBrowsing() => true,
    MatchIdle() ||
    MatchBlocked() ||
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
  void onInit() {
    super.onInit();
    _pendingCancels.addAll(_storedCancels());
    SessionHub.instance.register(_sessionName, (_) => _teardown());
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => unawaited(flushPendingCancels()));
    _monitor = ConnectionMonitor.current;
    _monitor?.status.addListener(_onConnectionChanged);
    unawaited(flushPendingCancels());
  }

  @override
  void onClose() {
    _teardown();
    _resumeSubscription?.cancel();
    _monitor?.status.removeListener(_onConnectionChanged);
    SessionHub.instance.unregister(_sessionName);
    super.onClose();
  }

  void _teardown() {
    _invalidate();
    _create?.dispose();
    _create = null;
    _confirmMutation?.dispose();
    _confirmMutation = null;
    _requestId = null;
    _state.value = const MatchIdle();
  }

  void _onConnectionChanged() {
    final status = _monitor?.status.value ?? ConnectionStatus.online;
    final recovered = status == ConnectionStatus.online && _lastStatus != ConnectionStatus.online;
    _lastStatus = status;
    if (recovered) unawaited(flushPendingCancels());
  }

  int _invalidate() {
    _stopSearchPolling();
    _stopApprovalPolling();
    stopOffersRefresh();
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
    await _send(payload);
  }

  Mutation<CreateOutcome> _createFor(Map<String, dynamic> payload) {
    final signature = payload.toString();
    final existing = _create;
    if (existing != null && _createSignature == signature) return existing;
    existing?.dispose();
    _createSignature = signature;
    return _create = Mutation<CreateOutcome>(
      intent: 'ride-request',
      run: (key) async {
        final response = await _api.post(AppEndpoints.rideRequests, data: payload, key: key, suppressErrorToast: true);
        final data = _dataOf(response.data);
        if (data['status'] == 'scheduled') return RequestScheduled(ScheduledBooking.fromJson(data));
        return RequestCreated(MatchRequest.fromJson(data));
      },
      reconcile: _reconcileCreate,
    );
  }

  Future<Reconciled<CreateOutcome>> _reconcileCreate() async {
    final response = await _api.get(
      AppEndpoints.meState,
      suppressErrorToast: true,
      profile: RequestProfile.interactive,
    );
    final active = MeState.fromEnvelope(response.data).activeRideRequest;
    if (active == null) return const ReconciledNotDone();
    final request = await _api.get(AppEndpoints.rideRequestOf(active.id), suppressErrorToast: true);
    return ReconciledDone(RequestCreated(MatchRequest.fromJson(_dataOf(request.data))));
  }

  Future<void> _send(Map<String, dynamic> payload) async {
    final epoch = _invalidate();
    _requestId = null;
    _state.value = const MatchStarting();
    final mutation = _createFor(payload);
    void follow() {
      if (epoch == _epoch && mutation.state.value is MutationChecking<CreateOutcome>) {
        _state.value = const MatchStarting(isChecking: true);
      }
    }

    mutation.state.addListener(follow);
    final MutationState<CreateOutcome> result;
    try {
      result = await mutation.start();
    } finally {
      mutation.state.removeListener(follow);
    }
    if (epoch != _epoch) return _settleAbandonedCreate(result);
    _handleCreate(result, payload, mutation);
  }

  void _handleCreate(MutationState<CreateOutcome> result, Map<String, dynamic> payload, Mutation<CreateOutcome> m) {
    switch (result) {
      case MutationDone<CreateOutcome>(:final value):
        _onCreated(value);
      case MutationRejected<CreateOutcome>(:final error):
        m.reset();
        _reject(error, payload);
      case MutationFailed<CreateOutcome>(:final error):
        _state.value = MatchFailed(MatchFailure.of(error));
      case MutationUnknown<CreateOutcome>() ||
          MutationIdle<CreateOutcome>() ||
          MutationRunning<CreateOutcome>() ||
          MutationChecking<CreateOutcome>():
        _state.value = const MatchFailed(MatchFailure.unconfirmed);
    }
  }

  void _onCreated(CreateOutcome outcome) {
    switch (outcome) {
      case RequestScheduled(:final booking):
        _state.value = MatchScheduled(booking);
      case RequestCreated(:final request):
        _requestId = request.id;
        _approvalId = null;
        _approvalPayload = null;
        _persist();
        _refreshRestore();
        _applyRequest(request);
    }
  }

  void _settleAbandonedCreate(MutationState<CreateOutcome> result) {
    switch (result) {
      case MutationDone<CreateOutcome>(value: RequestCreated(:final request)):
        unawaited(_cancelOnServer(request.id));
      case MutationRejected<CreateOutcome>() || MutationFailed<CreateOutcome>() || MutationDone<CreateOutcome>():
        break;
      case MutationUnknown<CreateOutcome>() ||
          MutationIdle<CreateOutcome>() ||
          MutationRunning<CreateOutcome>() ||
          MutationChecking<CreateOutcome>():
        unawaited(_cancelStrayRequest());
    }
  }

  Future<void> _cancelStrayRequest() async {
    try {
      final reconciled = await _reconcileCreate();
      if (reconciled case ReconciledDone<CreateOutcome>(value: RequestCreated(:final request))) {
        await _cancelOnServer(request.id);
      }
    } catch (e) {
      log('stray request check failed: $e');
    }
  }

  void _reject(ApiException error, Map<String, dynamic> payload) {
    if (error.code == 'requires_approval') {
      _waitForApproval(payload, PendingApproval.fromData(error.data));
      return;
    }
    if (error.code == 'quote_expired') {
      _state.value = MatchFailed(MatchFailure.quoteExpired, code: error.code, data: error.data);
      return;
    }
    final block = GroupRideBlock.tryFromCode(error.code);
    _state.value = block == null
        ? MatchFailed(MatchFailure.couldNotStart, code: error.code, data: error.data)
        : MatchBlocked(block);
  }

  void _waitForApproval(Map<String, dynamic> payload, PendingApproval approval) {
    final epoch = _invalidate();
    _approvalId = approval.id;
    _approvalPayload = payload;
    _persist();
    _state.value = MatchAwaitingApproval(approval);
    _approvalPoller = LivePoller(
      fetch: () => _pollApproval(epoch, payload, approval),
      interval: approvalPollInterval,
      onParseError: (error, _) => log('approval poll unreadable: $error'),
    )..start();
  }

  void _stopApprovalPolling() {
    _approvalPoller?.dispose();
    _approvalPoller = null;
  }

  Future<void> _pollApproval(int epoch, Map<String, dynamic> payload, PendingApproval approval) async {
    if (epoch != _epoch || state is! MatchAwaitingApproval) return;
    final response = await _api.get(GroupEndpoints.approvalAt(approval.id), suppressErrorToast: true);
    if (epoch != _epoch) return;
    final status = RideApproval.fromJson(_dataOf(response.data)).status;
    if (status == ApprovalStatus.approved) {
      _stopApprovalPolling();
      unawaited(_send({...payload, 'approvalId': approval.id}));
    } else if (status == ApprovalStatus.declined) {
      _finishApproval(const MatchBlocked(GroupRideBlock.approvalDeclined));
    } else if (status == ApprovalStatus.expired) {
      _finishApproval(const MatchBlocked(GroupRideBlock.approvalExpired));
    }
  }

  void _finishApproval(RideMatchState next) {
    _stopApprovalPolling();
    _approvalId = null;
    _approvalPayload = null;
    _persist();
    _state.value = next;
  }

  Future<void> retry() async {
    if (isStarting) return;
    if (isLive) await cancelRequest();
    await requestRide();
  }

  Future<void> recheck() async {
    final id = _requestId;
    if (id != null) return _resumeRequest(id);
    final mutation = _create;
    if (mutation == null) return;
    final epoch = _epoch;
    _state.value = const MatchStarting(isChecking: true);
    final result = await mutation.recheck();
    if (epoch != _epoch) return;
    _handleCreate(result, const {}, mutation);
  }

  Future<void> resume() async {
    if (isLive || state is MatchBlocked || state is MatchNoDriver) return;
    final draft = SessionStorage.drafts.read(_draftKey);
    final restore = Get.isRegistered<SessionRestore>() ? Get.find<SessionRestore>() : null;
    final id = restore?.pendingRideRequestId ?? draft?['requestId'] as String?;
    if (id != null && !_pendingCancels.contains(id)) return _resumeRequest(id);
    final approvalId = draft?['approvalId'] as String?;
    final payload = draft?['payload'];
    if (approvalId != null && payload is Map) {
      _waitForApproval(Map<String, dynamic>.from(payload), PendingApproval(approvalId));
    }
  }

  Future<void> _resumeRequest(String id) async {
    final epoch = _invalidate();
    _requestId = id;
    _state.value = const MatchResuming();
    try {
      final response = await _api.get(AppEndpoints.rideRequestOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      _applyRequest(MatchRequest.fromJson(_dataOf(response.data)), immediate: true);
    } on ApiException catch (e) {
      if (epoch != _epoch) return;
      if (e.kind == ApiFailureKind.rejected) {
        _requestId = null;
        _persist();
        _state.value = const MatchCancelled();
      } else {
        _state.value = const MatchFailed(MatchFailure.connectionLost);
      }
    } catch (e) {
      log('resume request failed: $e');
      if (epoch == _epoch) _state.value = const MatchFailed(MatchFailure.connectionLost);
    }
  }

  Future<bool> cancelRequest() async {
    if (state is MatchAwaitingApproval) {
      abandon();
      return true;
    }
    final id = _requestId;
    if (id == null) return false;
    _invalidate();
    final isSettled = await _cancelOnServer(id);
    _requestId = null;
    _persist();
    _state.value = MatchCancelled(isConfirmed: isSettled);
    return true;
  }

  void abandon() {
    if (!isLive) return;
    final id = _requestId;
    _invalidate();
    _requestId = null;
    _approvalId = null;
    _approvalPayload = null;
    _persist();
    _state.value = const MatchCancelled();
    if (id != null) unawaited(_cancelOnServer(id));
  }

  Future<bool> _cancelOnServer(String id) async {
    _pendingCancels.add(id);
    _saveCancels();
    if (ConnectionMonitor.current?.isOnline == false) return false;
    try {
      await _api.post(
        AppEndpoints.rideRequestCancelOf(id),
        key: IdempotencyKey('cancel-ride-request-$id'),
        suppressErrorToast: true,
      );
    } on ApiException catch (e) {
      if (e.kind != ApiFailureKind.rejected) return false;
    } catch (e) {
      log('cancel of $id failed: $e');
      return false;
    }
    _pendingCancels.remove(id);
    _saveCancels();
    _refreshRestore();
    return true;
  }

  Future<void> flushPendingCancels() async {
    if (_isFlushingCancels || _pendingCancels.isEmpty || !SessionStorage.tokens.hasSession) return;
    _isFlushingCancels = true;
    try {
      for (final id in _pendingCancels.toList()) {
        if (!await _cancelOnServer(id)) break;
      }
    } finally {
      _isFlushingCancels = false;
    }
  }

  Set<String> _storedCancels() {
    final stored = SessionStorage.drafts.read(_cancelsKey)?['ids'];
    return stored is List
        ? {
            for (final id in stored)
              if (id is String) id,
          }
        : {};
  }

  void _saveCancels() {
    if (_pendingCancels.isEmpty) {
      unawaited(SessionStorage.drafts.remove(_cancelsKey));
    } else {
      unawaited(SessionStorage.drafts.write(_cancelsKey, {'ids': _pendingCancels.toList()}));
    }
  }

  void _persist() {
    final id = _requestId;
    final approvalId = _approvalId;
    if (id == null && approvalId == null) {
      unawaited(SessionStorage.drafts.remove(_draftKey));
      return;
    }
    unawaited(
      SessionStorage.drafts.write(_draftKey, {
        'requestId': ?id,
        'approvalId': ?approvalId,
        'payload': ?_approvalPayload,
      }),
    );
  }

  void _refreshRestore() {
    if (Get.isRegistered<SessionRestore>()) unawaited(Get.find<SessionRestore>().refreshQuietly());
  }

  void _applyRequest(MatchRequest request, {bool immediate = false}) {
    if (state is! MatchStarting && state is! MatchSearching && state is! MatchResuming) return;
    if (request.hasSearchExpired) {
      _finishSearch(const MatchNoDriver());
      return;
    }
    switch (request.status) {
      case RideRequestStatus.searching ||
          RideRequestStatus.checking ||
          RideRequestStatus.sending ||
          RideRequestStatus.unknown:
        _state.value = MatchSearching(request, link: _searchPoller?.link.value ?? LinkState.live);
        if (_searchPoller == null) _startPolling(request);
      case RideRequestStatus.offers:
        final continueAt = immediate ? DateTime.now() : DateTime.now().add(autoContinueAfter);
        _finishSearch(MatchOffersReady(request: request, continueAt: continueAt));
      case RideRequestStatus.noDriverFound:
        _finishSearch(const MatchNoDriver());
      case RideRequestStatus.cancelled:
        _finishSearch(const MatchCancelled());
    }
  }

  void _finishSearch(RideMatchState next) {
    _stopSearchPolling();
    if (next is MatchNoDriver || next is MatchCancelled) {
      _requestId = null;
      _persist();
    }
    _state.value = next;
  }

  void _startPolling(MatchRequest request) {
    _stopSearchPolling();
    final epoch = _epoch;
    final poller = LivePoller(
      fetch: () => _pollOnce(epoch),
      interval: pollInterval,
      onParseError: (error, _) => log('poll unreadable: $error'),
    );
    poller.link.addListener(() => _onLink(epoch, poller));
    _searchPoller = poller..start();
    _expiryTimer = Timer(ServerClock.instance.remaining(request.searchDeadline) + retryDelay, () => _onExpiry(epoch));
  }

  void _stopSearchPolling() {
    _searchPoller?.dispose();
    _searchPoller = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> _pollOnce(int epoch) async {
    final id = _requestId;
    if (id == null || epoch != _epoch) return;
    final MatchRequest request;
    try {
      final response = await _api.get(AppEndpoints.rideRequestOf(id), suppressErrorToast: true);
      request = MatchRequest.fromJson(_dataOf(response.data));
    } on ApiException catch (e) {
      if (epoch == _epoch && e.kind == ApiFailureKind.rejected && e.statusCode == 404) {
        _finishSearch(const MatchCancelled());
        return;
      }
      rethrow;
    }
    if (epoch == _epoch) _applyRequest(request);
  }

  void _onLink(int epoch, LivePoller poller) {
    if (epoch != _epoch) return;
    final current = state;
    if (current is! MatchSearching) return;
    final link = poller.link.value;
    if (current.link != link) _state.value = MatchSearching(current.request, link: link);
  }

  void _onExpiry(int epoch) {
    final current = state;
    if (epoch != _epoch || current is! MatchSearching || !current.isReconnecting) return;
    _stopSearchPolling();
    _state.value = const MatchFailed(MatchFailure.connectionLost);
  }

  Future<void> loadOffers() async {
    final id = _requestId;
    if (id == null || (state is! MatchOffersReady && state is! MatchOffersFailed)) return;
    final epoch = _epoch;
    _state.value = const MatchOffersLoading();
    try {
      final rows = await _fetchOffers(id);
      if (epoch != _epoch) return;
      _state.value = MatchOffersListed(rows);
    } catch (e) {
      log('loadOffers failed: $e');
      if (epoch == _epoch) _state.value = MatchOffersFailed(problem: RideLoadProblem.of(e));
    }
  }

  Future<List<OfferRow>> _fetchOffers(String id) async {
    final response = await _api.get(AppEndpoints.rideRequestOffersOf(id), suppressErrorToast: true);
    return JsonReader.of(_dataOf(response.data)).listOf('offers', (item) => OfferRow(DriverOffer.fromJson(item)));
  }

  void startOffersRefresh() {
    if (_offersPoller != null) return;
    final epoch = _epoch;
    _offersPoller = LivePoller(
      fetch: () => _refreshOffers(epoch),
      interval: offersRefreshInterval,
      onParseError: (error, _) => log('offers unreadable: $error'),
    )..start();
  }

  void stopOffersRefresh() {
    _offersPoller?.dispose();
    _offersPoller = null;
  }

  Future<void> _refreshOffers(int epoch) async {
    final id = _requestId;
    if (id == null || epoch != _epoch || !_canMergeOffers(state)) return;
    final fresh = await _fetchOffers(id);
    final latest = state;
    if (epoch != _epoch || latest is! MatchBrowsing || !_canMergeOffers(latest)) return;
    _state.value = latest.withRows(_merged(latest.rows, fresh));
  }

  bool _canMergeOffers(RideMatchState current) => switch (current) {
    MatchOffersListed(:final acceptingOfferId) => acceptingOfferId == null,
    MatchHolding(:final isConfirming) => !isConfirming,
    _ => false,
  };

  List<OfferRow> _merged(List<OfferRow> current, List<OfferRow> fresh) {
    final leaving = {
      for (final row in current)
        if (row.isLeaving) row.offer.id,
    };
    return [
      for (final row in fresh)
        if (!leaving.contains(row.offer.id)) row,
    ];
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
    final key = IdempotencyKey.newFor('ignore-offer');
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _api.post(AppEndpoints.rideOfferIgnoreOf(id, offerId), key: key, suppressErrorToast: true);
        return;
      } catch (e) {
        log('ignore failed: $e');
        await Future<void>.delayed(retryDelay);
      }
    }
    if (_requestId == id) unawaited(_refreshOffers(_epoch));
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
      final response = await _api.post(
        AppEndpoints.rideOfferHoldOf(id, offer.id),
        key: IdempotencyKey.newFor('hold-offer'),
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return false;
      _state.value = MatchHolding(
        current.rows,
        hold: DriverHold.fromJson(_dataOf(response.data), etaMinutes: offer.etaMinutes),
      );
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
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _api.delete(AppEndpoints.rideRequestHoldOf(id), suppressErrorToast: true);
        return;
      } on ApiException catch (e) {
        if (e.kind == ApiFailureKind.rejected) return;
        log('releaseHold failed: $e');
      }
      await Future<void>.delayed(retryDelay);
    }
    if (_requestId == id) unawaited(_refreshOffers(_epoch));
  }

  Future<void> expireHold() async {
    if (state is! MatchHolding) return;
    SangaToast.show(OfferUnavailableReason.holdExpired.message, tone: SangaToastTone.warning);
    await releaseHold();
  }

  Mutation<ConfirmedTrip> _confirmFor(DriverHold hold) {
    final signature = '${hold.offerId}@${hold.holdExpiresAt.millisecondsSinceEpoch}';
    final existing = _confirmMutation;
    if (existing != null && _confirmSignature == signature) return existing;
    existing?.dispose();
    _confirmSignature = signature;
    final requestId = _requestId;
    return _confirmMutation = Mutation<ConfirmedTrip>(
      intent: 'confirm-driver',
      run: (key) async {
        final response = await _api.post(
          AppEndpoints.rideOfferConfirmOf(requestId!, hold.offerId),
          key: key,
          suppressErrorToast: true,
        );
        return ConfirmedTrip.fromJson(_dataOf(response.data));
      },
      reconcile: () => _reconcileConfirm(hold),
    );
  }

  Future<Reconciled<ConfirmedTrip>> _reconcileConfirm(DriverHold hold) async {
    final response = await _api.get(AppEndpoints.activeTrip, suppressErrorToast: true);
    final tripId = JsonReader.of((response.data as Map)['data']).strOrNull('id');
    if (tripId == null) return const ReconciledNotDone();
    return ReconciledDone(ConfirmedTrip(tripId: tripId, etaMinutes: hold.etaMinutes, driver: hold.driver));
  }

  Future<bool> confirm() async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchHolding || current.isConfirming) return false;
    final epoch = _epoch;
    final mutation = _confirmFor(current.hold);
    _state.value = MatchHolding(current.rows, hold: current.hold, isConfirming: true);
    final result = await mutation.start();
    if (epoch != _epoch) return false;
    switch (result) {
      case MutationDone<ConfirmedTrip>(:final value):
        _requestId = null;
        _persist();
        _state.value = MatchConfirmed(value);
        _refreshRestore();
        return true;
      case MutationRejected<ConfirmedTrip>(:final error):
        mutation.reset();
        _backToOffers(error, current.hold.offerId);
      case MutationFailed<ConfirmedTrip>(:final error):
        _state.value = MatchHolding(current.rows, hold: current.hold);
        SangaToast.show(OfferUnavailableReason.of(error).message, tone: SangaToastTone.error);
      case MutationUnknown<ConfirmedTrip>() ||
          MutationIdle<ConfirmedTrip>() ||
          MutationRunning<ConfirmedTrip>() ||
          MutationChecking<ConfirmedTrip>():
        _state.value = MatchHolding(current.rows, hold: current.hold);
        SangaToast.show(
          'We couldn’t confirm that. Tap confirm again. We won’t book it twice.',
          tone: SangaToastTone.warning,
        );
        _refreshRestore();
    }
    return false;
  }

  void _backToOffers(Object error, String offerId) {
    final current = state;
    if (current is! MatchBrowsing) return;
    final reason = OfferUnavailableReason.of(error);
    _state.value = MatchOffersListed([
      for (final row in current.rows) reason.removesOffer && row.offer.id == offerId ? row.asWithdrawn() : row,
    ]);
    SangaToast.show(reason.message, tone: SangaToastTone.error);
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
