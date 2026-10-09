import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

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
  IdempotencyKey? _shareKey;
  final Set<String> _inFlight = {};
  final Map<String, Mutation<Trip>> _actions = {};

  Rx<TripState> get stateRx => _state;

  TripState get state => _state.value;

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
    _startTripPoller();
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
    if (_tripId == null || state is! TripFailed) return;
    _state.value = const TripLoading();
    final poller = _tripPoller;
    if (poller == null || !poller.isRunning) {
      _startTripPoller();
      return;
    }
    await poller.refreshNow();
  }

  void _startTripPoller() {
    _detachTripLink?.call();
    _tripPoller?.dispose();
    final poller = LivePoller(fetch: _fetchTrip, interval: pollInterval, onParseError: _onParseError);
    void mirror() => _link.value = poller.link.value;
    poller.link.addListener(mirror);
    _detachTripLink = () => poller.link.removeListener(mirror);
    _tripPoller = poller;
    poller.start();
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
      final response = await _api.get(
        AppEndpoints.liveTripOf(id),
        suppressErrorToast: true,
        profile: isFirstLoad ? RequestProfile.interactive : RequestProfile.background,
      );
      if (!_epoch.isCurrent(epoch)) return;
      _accept(Trip.fromJson(response.dataMapOrEmpty), seq);
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

  void _accept(Trip incoming, int seq) {
    if (seq <= _applied) return;
    final current = trip;
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
    }
  }

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

  Future<bool> confirmDetails() => _act(
    flag: isConfirmingDetails,
    name: 'confirm-details',
    signature: '',
    send: (key) => _post(AppEndpoints.liveTripConfirmDetailsOf, key: key),
    didHappen: (trip) =>
        trip.hasEvent(TripEventType.detailsConfirmed) || trip.status.rank > TripStatus.driverArrived.rank,
  );

  Future<bool> refreshPin() {
    final before = trip?.pin;
    return _act(
      flag: isRefreshingPin,
      name: 'refresh-pin',
      signature: before ?? '',
      send: (key) => _post(AppEndpoints.liveTripPinRefreshOf, key: key),
      didHappen: (trip) => trip.pin != null && trip.pin != before,
    );
  }

  Future<bool> completeRide() => _act(
    flag: isCompleting,
    name: 'complete',
    signature: '',
    send: (key) => _post(AppEndpoints.liveTripCompleteOf, key: key),
    didHappen: (trip) => trip.status == TripStatus.completed,
    onDone: (_) => _signalEnded(),
  );

  Future<bool> reportIssue(Iterable<TripIssue> issues) {
    if (issues.isEmpty) return Future.value(false);
    final reasons = [for (final issue in issues) issue.code]..sort();
    return _act(
      flag: isReporting,
      name: 'report',
      signature: reasons.join(','),
      send: (key) => _post(AppEndpoints.liveTripReportOf, key: key, data: {'reasons': reasons}),
      didHappen: (trip) => trip.status == TripStatus.cancelled,
    );
  }

  Future<Trip> _post(
    String Function(String id) endpoint, {
    required IdempotencyKey key,
    Map<String, dynamic>? data,
  }) async {
    final id = _tripId;
    if (id == null) throw const ApiException(kind: ApiFailureKind.rejected, message: 'No trip', isMutation: true);
    final response = await _api.post(endpoint(id), data: data, key: key, suppressErrorToast: true);
    return Trip.fromJson(response.dataMapOrEmpty);
  }

  Future<bool> _act({
    required RxBool flag,
    required String name,
    required String signature,
    required Future<Trip> Function(IdempotencyKey key) send,
    required bool Function(Trip trip) didHappen,
    void Function(Trip trip)? onDone,
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
      return _settleAction(result, mutationKey, onDone);
    } finally {
      if (_epoch.isCurrent(epoch)) flag.value = false;
    }
  }

  bool _settleAction(MutationState<Trip> result, String mutationKey, void Function(Trip trip)? onDone) {
    switch (result) {
      case MutationDone<Trip>(:final value):
        _acceptFresh(value);
        onDone?.call(value);
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
      final response = await _api.get(
        AppEndpoints.liveTripOf(id),
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      return Trip.fromJson(response.dataMapOrEmpty);
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

  Future<void> openChat() async {
    if (_tripId == null) return;
    _isChatOpen.value = true;
    chatStatus.value = messages.isEmpty ? TripChatStatus.loading : TripChatStatus.ready;
    _startChatPoller();
  }

  void closeChat() {
    _isChatOpen.value = false;
    _detachChatLink?.call();
    _detachChatLink = null;
    _chatPoller?.dispose();
    _chatPoller = null;
    _chatLink.value = LinkState.live;
  }

  void _startChatPoller() {
    _detachChatLink?.call();
    _chatPoller?.dispose();
    final poller = LivePoller(fetch: _fetchChat, interval: pollInterval, onParseError: _onParseError);
    void mirror() => _chatLink.value = poller.link.value;
    poller.link.addListener(mirror);
    _detachChatLink = () => poller.link.removeListener(mirror);
    _chatPoller = poller;
    if (_isTerminal) {
      unawaited(poller.refreshNow().whenComplete(poller.stop));
    } else {
      poller.start();
    }
  }

  Future<void> reloadChat() async {
    chatStatus.value = TripChatStatus.loading;
    await _chatPoller?.refreshNow();
  }

  Future<void> _fetchChat() async {
    final id = _tripId;
    if (id == null) return;
    final epoch = _epoch.current;
    try {
      final response = await _api.get(AppEndpoints.liveTripMessagesOf(id), suppressErrorToast: true);
      if (!_epoch.isCurrent(epoch) || !isChatOpen) return;
      final server = JsonReader.of(response.dataMapOrEmpty)
          .listOf('messages', (item) => TripMessage.fromJson(item.raw));
      _mergeServerMessages(server);
      chatStatus.value = TripChatStatus.ready;
    } catch (error) {
      if (_epoch.isCurrent(epoch) && messages.isEmpty) chatStatus.value = TripChatStatus.failed;
      rethrow;
    }
  }

  void _mergeServerMessages(List<TripMessage> server) {
    final serverClientIds = {for (final message in server) ?message.clientId};
    final local = [
      for (final message in messages)
        if (message.delivery != TripMessageDelivery.sent && !serverClientIds.contains(message.clientId)) message,
    ];
    messages.assignAll([...server, ...local]..sort((a, b) => a.sentAt.compareTo(b.sentAt)));
  }

  Future<void> sendMessage(String text) async {
    final body = text.trim();
    if (body.isEmpty || _tripId == null) return;
    final clientId = 'client_${DateTime.now().microsecondsSinceEpoch}_${_clientCounter++}';
    messages.add(TripMessage.pending(clientId: clientId, body: body));
    await _deliver(clientId, body);
  }

  Future<void> retryMessage(String clientId) async {
    final index = messages.indexWhere((message) => message.clientId == clientId);
    if (index < 0 || messages[index].delivery != TripMessageDelivery.failed) return;
    final body = messages[index].body;
    messages[index] = messages[index].withDelivery(TripMessageDelivery.sending);
    await _deliver(clientId, body);
  }

  Future<void> _deliver(String clientId, String body) async {
    final id = _tripId;
    if (id == null || !_inFlight.add(clientId)) return;
    if (LiveProblem.isOffline) {
      _inFlight.remove(clientId);
      _markDelivery(clientId, TripMessageDelivery.failed);
      return;
    }
    final epoch = _epoch.current;
    try {
      final response = await _api.post(
        AppEndpoints.liveTripMessagesOf(id),
        data: {'body': body, 'clientId': clientId},
        key: IdempotencyKey(IdempotencyIntent.tripChatKey(clientId)),
        suppressErrorToast: true,
      );
      if (!_epoch.isCurrent(epoch)) return;
      _replaceByClientId(clientId, TripMessage.fromJson(response.dataMapOrEmpty));
    } catch (error) {
      log('sendMessage failed: $error', name: 'TripController');
      if (_epoch.isCurrent(epoch)) _markDelivery(clientId, TripMessageDelivery.failed);
    } finally {
      _inFlight.remove(clientId);
    }
  }

  void _replaceByClientId(String clientId, TripMessage saved) {
    final index = messages.indexWhere((message) => message.clientId == clientId);
    if (index < 0) {
      messages.add(saved);
    } else {
      messages[index] = saved;
    }
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  void _markDelivery(String clientId, TripMessageDelivery delivery) {
    final index = messages.indexWhere((message) => message.clientId == clientId);
    if (index >= 0) messages[index] = messages[index].withDelivery(delivery);
  }
}
