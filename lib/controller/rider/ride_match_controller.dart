import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

part 'ride_match_cancels.dart';
part 'ride_match_confirm.dart';
part 'ride_match_offers.dart';

class RideMatchController extends GetxController {
  static const Duration pollInterval = Duration(milliseconds: 1500);
  static const Duration approvalPollInterval = Duration(seconds: 2);
  static const Duration offersRefreshInterval = Duration(seconds: 5);
  static const Duration autoContinueAfter = Duration(seconds: 5);
  static const Duration rowExitDuration = SangaMotion.morph;
  static const Duration retryDelay = Duration(seconds: 2);

  final _api = Get.find<ApiService>();
  final _trip = Get.find<RideRequestController>();

  final Rx<RideMatchState> _state = Rx<RideMatchState>(const MatchIdle());
  final PendingRideCancels _cancels = PendingRideCancels();

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
  final _epoch = Epoch();
  bool _isFlushingCancels = false;

  Rx<RideMatchState> get stateRx => _state;

  RideMatchState get state => _state.value;

  bool get isStarting => state is MatchStarting;

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
    _cancels.load();
    SessionHub.instance.register(SessionNames.rideMatch, (_) => _teardown());
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
    SessionHub.instance.unregister(SessionNames.rideMatch);
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
    return _epoch.next();
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
      intent: IdempotencyIntent.rideRequest,
      run: (key) async {
        final response = await _api.post(AppEndpoints.rideRequests, data: payload, key: key, suppressErrorToast: true);
        final data = response.dataMap;
        final status = RideRequestStatus.fromCode(JsonReader.of(data).strOrNull('status'));
        if (status == RideRequestStatus.scheduled) return RequestScheduled(ScheduledBooking.fromJson(data));
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
    return ReconciledDone(RequestCreated(MatchRequest.fromJson(request.dataMap)));
  }

  Future<void> _send(Map<String, dynamic> payload) async {
    final epoch = _invalidate();
    _requestId = null;
    _state.value = const MatchStarting();
    final mutation = _createFor(payload);
    void follow() {
      if (_epoch.isCurrent(epoch) && mutation.state.value is MutationChecking<CreateOutcome>) {
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
    if (!_epoch.isCurrent(epoch)) return _settleAbandonedCreate(result);
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
    if (error.code == ServerCode.requiresApproval) {
      _waitForApproval(payload, PendingApproval.fromData(error.data));
      return;
    }
    if (error.code == ServerCode.quoteExpired) {
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
    if (!_epoch.isCurrent(epoch) || state is! MatchAwaitingApproval) return;
    final response = await _api.get(GroupEndpoints.approvalAt(approval.id), suppressErrorToast: true);
    if (!_epoch.isCurrent(epoch)) return;
    final status = RideApproval.fromJson(response.dataMap).status;
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
    final epoch = _epoch.current;
    _state.value = const MatchStarting(isChecking: true);
    final result = await mutation.recheck();
    if (!_epoch.isCurrent(epoch)) return;
    _handleCreate(result, const {}, mutation);
  }

  Future<void> resume() async {
    if (isLive || state is MatchBlocked || state is MatchNoDriver) return;
    final draft = SessionStorage.drafts.read(DraftKeys.rideMatch);
    final restore = Get.isRegistered<SessionRestore>() ? Get.find<SessionRestore>() : null;
    final id = restore?.pendingRideRequestId ?? draft?['requestId'] as String?;
    if (id != null && !_cancels.contains(id)) return _resumeRequest(id);
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
      if (!_epoch.isCurrent(epoch)) return;
      _applyRequest(MatchRequest.fromJson(response.dataMap), immediate: true);
    } on ApiException catch (e) {
      if (!_epoch.isCurrent(epoch)) return;
      if (e.kind == ApiFailureKind.rejected) {
        _requestId = null;
        _persist();
        _state.value = const MatchCancelled();
      } else {
        _state.value = const MatchFailed(MatchFailure.connectionLost);
      }
    } catch (e) {
      log('resume request failed: $e');
      if (_epoch.isCurrent(epoch)) _state.value = const MatchFailed(MatchFailure.connectionLost);
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

  void _persist() {
    final id = _requestId;
    final approvalId = _approvalId;
    if (id == null && approvalId == null) {
      unawaited(SessionStorage.drafts.remove(DraftKeys.rideMatch));
      return;
    }
    unawaited(
      SessionStorage.drafts.write(DraftKeys.rideMatch, {
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
          RideRequestStatus.scheduled ||
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
    final epoch = _epoch.current;
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
    if (id == null || !_epoch.isCurrent(epoch)) return;
    final MatchRequest request;
    try {
      final response = await _api.get(AppEndpoints.rideRequestOf(id), suppressErrorToast: true);
      request = MatchRequest.fromJson(response.dataMap);
    } on ApiException catch (e) {
      if (_epoch.isCurrent(epoch) && e.kind == ApiFailureKind.rejected && e.isNotFound) {
        _finishSearch(const MatchCancelled());
        return;
      }
      rethrow;
    }
    if (_epoch.isCurrent(epoch)) _applyRequest(request);
  }

  void _onLink(int epoch, LivePoller poller) {
    if (!_epoch.isCurrent(epoch)) return;
    final current = state;
    if (current is! MatchSearching) return;
    final link = poller.link.value;
    if (current.link != link) _state.value = MatchSearching(current.request, link: link);
  }

  void _onExpiry(int epoch) {
    final current = state;
    if (!_epoch.isCurrent(epoch) || current is! MatchSearching || !current.isReconnecting) return;
    _stopSearchPolling();
    _state.value = const MatchFailed(MatchFailure.connectionLost);
  }
}
