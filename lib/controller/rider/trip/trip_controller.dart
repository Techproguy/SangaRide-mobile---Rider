import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart' show RouteGeometry;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

part 'trip_chat.dart';

enum TripChatStatus { loading, ready, failed }

class TripController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 3);

  static const Duration noticeDuration = Duration(seconds: 4);

  final _api = Get.find<ApiService>();

  final Rx<TripState> _state = Rx<TripState>(const TripLoading());

  final Rx<LinkState> _link = Rx<LinkState>(LinkState.live);

  final Rx<LinkState> _chatLink = Rx<LinkState>(LinkState.live);

  final RxBool isConfirmingDetails = false.obs;

  final RxBool isRefreshingPin = false.obs;

  final RxBool isReporting = false.obs;

  final RxBool isCompleting = false.obs;

  final RxBool isCalling = false.obs;

  final Rxn<TripNotice> _notice = Rxn<TripNotice>();

  final RxList<TripMessage> messages = <TripMessage>[].obs;

  final Rx<TripChatStatus> chatStatus = Rx<TripChatStatus>(TripChatStatus.loading);

  final RxBool _isChatOpen = false.obs;

  LivePoller? _tripPoller;

  LivePoller? _chatPoller;

  VoidCallback? _detachTripLink;

  VoidCallback? _detachChatLink;

  Timer? _noticeTimer;

  String? _tripId;

  int _openers = 0;

  final Epoch _epoch = Epoch();

  int _seq = 0;

  int _applied = 0;

  int _clientCounter = 0;

  bool _hasSignalledEnd = false;

  bool _isRevealingPin = false;

  bool _hasReported = false;

  bool _hasCancelledAsRider = false;

  String? _pin;

  DateTime? _pinExpiresAt;

  DateTime? _detailsConfirmedAt;

  int _markedDriverMessages = 0;

  IdempotencyKey? _shareKey;

  final Set<String> _inFlight = {};

  final Map<String, Mutation<Trip>> _actions = {};

  Rx<TripState> get stateRx => _state;

  TripState get state => _state.value;

  static const double _headingMinMeters = 5;

  StreamSubscription<RideEvent>? _positionSubscription;

  DriverPosition? _livePosition;

  Rx<LinkState> get linkRx => _link;

  LinkState get link => _link.value;

  bool get isOffline => link == LinkState.lost;

  bool get isReconnecting => link == LinkState.reconnecting;

  bool get isChatStale => _chatLink.value != LinkState.live;

  bool get isChatOpen => _isChatOpen.value;

  String? get tripId => _tripId;

  TripNotice? get notice => _notice.value;

  Trip? get trip => switch (state) {
    TripLoaded(:final trip) => trip,
    _ => null,
  };

  int get unreadCount => isChatOpen ? 0 : (trip?.unreadMessages ?? 0);

  @override
  void onClose() {
    close();
    super.onClose();
  }

  Future<void> open(String tripId) async {
    if (_tripId == tripId) {
      _openers++;
      return;
    }
    _teardown();
    _tripId = tripId;
    _openers = 1;
    _epoch.next();
    _state.value = const TripLoading();
    _startTripPoller(tripId);
  }

  void close({String? onlyTripId}) {
    if (onlyTripId != null) {
      if (onlyTripId != _tripId) return;
      if (--_openers > 0) return;
    }
    _teardown();
  }

  void _teardown() {
    _detachTripLink?.call();
    _detachTripLink = null;
    _detachChatLink?.call();
    _detachChatLink = null;
    _tripPoller?.dispose();
    _tripPoller = null;
    _chatPoller?.dispose();
    _chatPoller = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _livePosition = null;
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _notice.value = null;
    for (final action in _actions.values) {
      action.dispose();
    }
    _actions.clear();
    _tripId = null;
    _openers = 0;
    _epoch.next();
    _seq = 0;
    _applied = 0;
    _hasSignalledEnd = false;
    _isRevealingPin = false;
    _hasReported = false;
    _hasCancelledAsRider = false;
    _pin = null;
    _pinExpiresAt = null;
    _detailsConfirmedAt = null;
    _markedDriverMessages = 0;
    _shareKey = null;
    _inFlight.clear();
    _state.value = const TripLoading();
    _link.value = LinkState.live;
    _chatLink.value = LinkState.live;
    _isChatOpen.value = false;
    isConfirmingDetails.value = false;
    isRefreshingPin.value = false;
    isReporting.value = false;
    isCompleting.value = false;
    messages.clear();
    chatStatus.value = TripChatStatus.loading;
  }

  Future<void> retryLoad() async {
    final id = _tripId;
    if (id == null || state is! TripFailed) return;
    _state.value = const TripLoading();
    final poller = _tripPoller;
    if (poller == null || !poller.isRunning) {
      _startTripPoller(id);
      return;
    }
    await poller.refreshNow();
  }

  void _startTripPoller(String id) {
    _detachTripLink?.call();
    _tripPoller?.dispose();
    final poller = LivePoller(
      fetch: _fetchTrip,
      interval: pollInterval,
      nudges: RideEvents.instance.about(id, ignoring: {RideEvents.driverLocation}),
      onParseError: _onParseError,
    );
    _livePosition = null;
    _positionSubscription?.cancel();
    _positionSubscription = RideEvents.instance.driverLocationsOf(id).listen(_onDriverLocation);
    void mirror() => _link.value = poller.link.value;
    poller.link.addListener(mirror);
    _detachTripLink = () => poller.link.removeListener(mirror);
    _tripPoller = poller;
    poller.start();
  }

  void _onDriverLocation(RideEvent event) {
    final data = JsonReader.of(event.data);
    final latitude = data.doubleOrNull('latitude');
    final longitude = data.doubleOrNull('longitude');
    if (latitude == null || longitude == null) return;
    final next = LatLng(latitude, longitude);
    final previous = _livePosition?.position;
    final moved = previous != null && previous.metersTo(next) >= _headingMinMeters;
    _livePosition = DriverPosition(
      position: next,
      heading: data.doubleOrNull('heading') ?? (moved ? RouteGeometry.bearing(previous, next) : _livePosition?.heading),
    );
    final current = trip;
    if (current == null || current.status.isTerminal) return;
    _state.value = TripState.of(current.withLocal(livePosition: _livePosition));
  }

  void _onParseError(Object error, StackTrace stack) {
    log('trip payload unreadable: $error', name: 'TripController');
  }

  Future<void> _fetchTrip() async {
    final id = _tripId;
    if (id == null) return;
    final epoch = _epoch.current;
    final seq = ++_seq;
    final isFirstLoad = state is TripLoading || state is TripFailed;
    try {
      final incoming = await _loadTrip(
        id,
        profile: isFirstLoad ? RequestProfile.interactive : RequestProfile.background,
      );
      if (!_epoch.isCurrent(epoch)) return;
      _accept(incoming, seq);
    } catch (error) {
      if (!_epoch.isCurrent(epoch)) return;
      if (error is ApiException && error.isGone) {
        _onTripGone();
        return;
      }
      if (isFirstLoad) _state.value = TripFailed(TripLoadFailure.of(error));
      rethrow;
    }
  }

  void _onTripGone() {
    _tripPoller?.stop();
    _chatPoller?.stop();
    _state.value = const TripFailed(TripLoadFailure.notFound);
    _signalEnded();
  }

  bool get _isTerminal => switch (state) {
    TripCompleted() || TripCancelled() || TripRefused() || TripReturned() || TripFailed() => true,
    _ => false,
  };

  Future<Trip> _loadTrip(String id, {RequestProfile profile = RequestProfile.interactive}) async {
    final response = await _api.get(AppEndpoints.liveTripOf(id), suppressErrorToast: true, profile: profile);
    return Trip.fromJson(response.dataMapOrEmpty);
  }

  Trip _withLocalFacts(Trip incoming) {
    if (incoming.status != TripStatus.driverArrived) {
      _pin = null;
      _pinExpiresAt = null;
    }
    return incoming.withLocal(
      pin: _pin,
      pinExpiresAt: _pinExpiresAt,
      detailsConfirmedAt: _detailsConfirmedAt,
      cancellationReason: _localCancelReason(incoming),
      livePosition: _livePosition,
    );
  }

  TripCancelReason? _localCancelReason(Trip incoming) {
    if (incoming.status != TripStatus.cancelled) return null;
    if (_hasReported) return TripCancelReason.driverMismatch;
    final reason = incoming.cancellationReason;
    final isUnattributed = reason == null || reason == TripCancelReason.other;
    return _hasCancelledAsRider && isUnattributed ? TripCancelReason.riderCancelled : null;
  }

  void _accept(Trip raw, int seq) {
    if (seq <= _applied) return;
    final current = trip;
    final incoming = _withLocalFacts(raw);
    final isReturnLeg = incoming.delivery?.stage.isReturn ?? false;
    if (current != null && !isReturnLeg && TripStatus.advance(current.status, incoming.status) != incoming.status) {
      return;
    }
    _applied = seq;
    if (incoming.isDelivery) unawaited(SessionStorage.drafts.remove(DraftKeys.deliveryDraft));
    _state.value = TripState.of(incoming);
    if (incoming.status.isTerminal) {
      _tripPoller?.stop();
      _chatPoller?.stop();
      _signalEnded();
      return;
    }
    if (_needsPin(incoming)) unawaited(_revealPin());
  }

  bool _needsPin(Trip trip) =>
      trip.status == TripStatus.driverArrived && trip.pin == null && trip.hasEvent(TripEventType.detailsConfirmed);

  Future<bool> _revealPin() async {
    final id = _tripId;
    if (id == null || _isRevealingPin) return false;
    _isRevealingPin = true;
    final epoch = _epoch.current;
    try {
      final response = await _api.post(AppEndpoints.liveTripPinRefreshOf(id), suppressErrorToast: true);
      if (!_epoch.isCurrent(epoch)) return false;
      return _storePin(response.dataMapOrEmpty);
    } catch (error) {
      log('pin reveal failed: $error', name: 'TripController');
      return false;
    } finally {
      _isRevealingPin = false;
    }
  }

  bool _storePin(Map<String, dynamic> reveal) {
    final data = JsonReader.of(reveal);
    final pin = data.strOrNull('pin');
    if (pin == null) return false;
    _pin = pin;
    _pinExpiresAt = deviceDeadlineOrNull(data.strOrNull('expiresAt'));
    final current = trip;
    if (current != null) _acceptFresh(current);
    return true;
  }

  Future<Trip> loadLatest() => _loadTrip(_requireTripId());

  void noteCancelledByRider() => _hasCancelledAsRider = true;

  void _signalEnded() {
    if (_hasSignalledEnd) return;
    _hasSignalledEnd = true;
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }

  void _acceptFresh(Trip incoming) => _accept(incoming, ++_seq);

  void applyServerTrip(Trip trip) => _acceptFresh(trip);

  Future<Trip?> pollNow() async {
    await _tripPoller?.refreshNow();
    return trip;
  }

  void announce(TripNotice notice) {
    _notice.value = notice;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(noticeDuration, () => _notice.value = null);
  }

  Future<bool> confirmDetails() async {
    final isDone = await _act(
      flag: isConfirmingDetails,
      name: 'confirm-details',
      signature: '',
      send: (key) async {
        final id = await _post(AppEndpoints.liveTripConfirmDetailsOf, key: key, data: {'matches': true});
        _detailsConfirmedAt ??= DateTime.now();
        await _revealPin();
        return _loadTrip(id);
      },
      didHappen: (trip) =>
          trip.hasEvent(TripEventType.detailsConfirmed) || trip.status.rank > TripStatus.driverArrived.rank,
    );
    if (isDone && state is TripArrived) SangaToast.show(LiveProblem.pinPending);
    return isDone;
  }

  Future<bool> refreshPin() {
    final before = trip?.pin;
    return _act(
      flag: isRefreshingPin,
      name: 'refresh-pin',
      signature: before ?? '',
      send: (key) async {
        final id = _requireTripId();
        final response = await _api.post(AppEndpoints.liveTripPinRefreshOf(id), key: key, suppressErrorToast: true);
        _storePin(response.dataMapOrEmpty);
        return _loadTrip(id);
      },
      didHappen: (trip) => trip.pin != null && trip.pin != before,
    );
  }

  Future<bool> completeRide() async {
    if (isCompleting.value) return false;
    isCompleting.value = true;
    try {
      final latest = await pollNow();
      return latest?.status == TripStatus.completed;
    } finally {
      isCompleting.value = false;
    }
  }

  Future<bool> reportIssue(Iterable<TripIssue> issues) {
    if (issues.isEmpty) return Future.value(false);
    final reasons = [for (final issue in issues) issue.code]..sort();
    return _act(
      flag: isReporting,
      name: 'report',
      signature: reasons.join(','),
      send: (key) async {
        _hasReported = true;
        try {
          final id = await _post(AppEndpoints.liveTripReportOf, key: key, data: {'reasons': reasons});
          return await _loadTrip(id);
        } catch (_) {
          _hasReported = false;
          rethrow;
        }
      },
      didHappen: (trip) => trip.status == TripStatus.cancelled,
    );
  }

  String _requireTripId() {
    final id = _tripId;
    if (id == null) throw const ApiException(kind: ApiFailureKind.rejected, message: 'No trip', isMutation: true);
    return id;
  }

  Future<String> _post(
    String Function(String id) endpoint, {
    required IdempotencyKey key,
    Map<String, dynamic>? data,
  }) async {
    final id = _requireTripId();
    await _api.post(endpoint(id), data: data, key: key, suppressErrorToast: true);
    return id;
  }

  Future<bool> _act({
    required RxBool flag,
    required String name,
    required String signature,
    required Future<Trip> Function(IdempotencyKey key) send,
    required bool Function(Trip trip) didHappen,
  }) async {
    final id = _tripId;
    if (id == null || flag.value) return false;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return false;
    }
    final epoch = _epoch.current;
    final mutationKey = '$name|$signature';
    final mutation = _actions.putIfAbsent(
      mutationKey,
      () => Mutation<Trip>(
        intent: IdempotencyIntent.tripAction(name),
        run: send,
        reconcile: () async {
          final fresh = await _fetchOnce(id);
          if (fresh == null) return const ReconciledPending();
          return didHappen(fresh) ? ReconciledDone(fresh) : const ReconciledNotDone();
        },
      ),
    );
    flag.value = true;
    try {
      final result = await mutation.start();
      if (!_epoch.isCurrent(epoch)) return false;
      return _settleAction(result, mutationKey);
    } finally {
      if (_epoch.isCurrent(epoch)) flag.value = false;
    }
  }

  bool _settleAction(MutationState<Trip> result, String mutationKey) {
    switch (result) {
      case MutationDone<Trip>(:final value):
        _acceptFresh(value);
        _discardAction(mutationKey);
        return true;
      case MutationRejected<Trip>(:final error):
        LiveProblem.toast(error);
        _discardAction(mutationKey);
        unawaited(pollNow());
        return false;
      case MutationFailed<Trip>(:final error):
        LiveProblem.toast(error);
        unawaited(pollNow());
        return false;
      case MutationUnknown<Trip>():
        SangaToast.show(LiveProblem.checking, tone: SangaToastTone.warning);
        unawaited(pollNow());
        return false;
      default:
        return false;
    }
  }

  void _discardAction(String mutationKey) => _actions.remove(mutationKey)?.dispose();

  Future<Trip?> _fetchOnce(String id) async {
    try {
      return await _loadTrip(id);
    } catch (error) {
      log('trip check failed: $error', name: 'TripController');
      return null;
    }
  }

  Future<String?> startCall() async {
    final id = _tripId;
    if (id == null || isCalling.value) return null;
    if (LiveProblem.isOffline) return null;
    isCalling.value = true;
    try {
      final response = await _api.post(AppEndpoints.liveTripCallOf(id), suppressErrorToast: true);
      return JsonReader.of(response.dataMapOrEmpty).strOrNull('maskedNumber');
    } catch (error) {
      log('startCall failed: $error', name: 'TripController');
      return null;
    } finally {
      isCalling.value = false;
    }
  }

  Future<String?> createShareLink() async {
    final id = _tripId;
    if (id == null) return null;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return null;
    }
    _shareKey ??= IdempotencyKey.newFor(IdempotencyIntent.tripShare);
    try {
      final response = await _api.post(AppEndpoints.tripShareOf(id), key: _shareKey, suppressErrorToast: true);
      return JsonReader.of(response.dataMapOrEmpty).str('url');
    } catch (error) {
      log('share link failed: $error', name: 'TripController');
      LiveProblem.toast(error);
      return null;
    }
  }
}
