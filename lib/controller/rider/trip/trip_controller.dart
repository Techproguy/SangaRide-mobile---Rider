import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';

enum TripChatStatus { loading, ready, failed }

class TripController extends GetxController {
  static const Duration pollInterval = Duration(seconds: 3);
  static const int maxMissedPolls = 3;
  static const Duration noticeDuration = Duration(seconds: 4);
  static const Duration refreshWait = Duration(milliseconds: 100);
  static const String genericFailure = 'We couldn’t reach the server. Give it another go.';
  static const String _shareLinkBase = 'https://sanga.ride/t/';

  static String shareLinkOf(String tripId) => '$_shareLinkBase$tripId';

  final _api = Get.find<ApiService>();

  final Rx<TripState> _state = Rx<TripState>(const TripLoading());
  final RxBool _isOffline = false.obs;
  final RxBool isConfirmingDetails = false.obs;
  final RxBool isRefreshingPin = false.obs;
  final RxBool isReporting = false.obs;
  final RxBool isCompleting = false.obs;
  final RxBool isCalling = false.obs;
  final Rxn<TripNotice> _notice = Rxn<TripNotice>();

  final RxList<TripMessage> messages = <TripMessage>[].obs;
  final Rx<TripChatStatus> chatStatus = Rx<TripChatStatus>(TripChatStatus.loading);
  final RxBool _isChatOpen = false.obs;

  AppLifecycleListener? _lifecycle;
  Timer? _poller;
  Timer? _chatPoller;
  Timer? _noticeTimer;
  String? _tripId;
  int _epoch = 0;
  int _seq = 0;
  int _applied = 0;
  int _missedPolls = 0;
  bool _isPolling = false;
  bool _isChatPolling = false;
  bool _isForeground = true;
  int _clientCounter = 0;
  final Set<String> _inFlight = {};

  Rx<TripState> get stateRx => _state;

  TripState get state => _state.value;

  bool get isOffline => _isOffline.value;

  bool get isChatOpen => _isChatOpen.value;

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
    if (_tripId == tripId) return;
    close();
    _tripId = tripId;
    final epoch = ++_epoch;
    _state.value = const TripLoading();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    await _poll();
    if (epoch == _epoch) _startPolling();
  }

  void close({String? onlyTripId}) {
    if (onlyTripId != null && onlyTripId != _tripId) return;
    _poller?.cancel();
    _poller = null;
    _chatPoller?.cancel();
    _chatPoller = null;
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _notice.value = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _tripId = null;
    _epoch++;
    _seq = 0;
    _applied = 0;
    _missedPolls = 0;
    _isPolling = false;
    _isChatPolling = false;
    _isForeground = true;
    _inFlight.clear();
    _state.value = const TripLoading();
    _isOffline.value = false;
    _isChatOpen.value = false;
    messages.clear();
    chatStatus.value = TripChatStatus.loading;
  }

  Future<void> retryLoad() async {
    final id = _tripId;
    if (id == null || state is! TripFailed) return;
    _state.value = const TripLoading();
    await _poll();
    _startPolling();
  }

  void _onLifecycle(AppLifecycleState lifecycle) {
    _isForeground = lifecycle == AppLifecycleState.resumed;
    if (_tripId == null) return;
    if (!_isForeground) {
      _poller?.cancel();
      _poller = null;
      _chatPoller?.cancel();
      _chatPoller = null;
      return;
    }
    _startPolling(immediate: true);
    if (isChatOpen) _startChatPolling(immediate: true);
  }

  bool get _isTerminal => switch (state) {
    TripCompleted() || TripCancelled() || TripRefused() || TripFailed() => true,
    _ => false,
  };

  void _startPolling({bool immediate = false}) {
    _poller?.cancel();
    _poller = null;
    if (_tripId == null || !_isForeground || _isTerminal) return;
    _poller = Timer.periodic(pollInterval, (_) => _poll());
    if (immediate) unawaited(_poll());
  }

  Future<void> _poll() async {
    final id = _tripId;
    if (id == null || _isPolling) return;
    _isPolling = true;
    final epoch = _epoch;
    final seq = ++_seq;
    try {
      final response = await _api.get(MockEndpoints.liveTripOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final trip = Trip.fromJson(_dataOf(response.data));
      _missedPolls = 0;
      _isOffline.value = false;
      _accept(trip, seq);
    } catch (e) {
      log('trip poll failed: $e');
      if (epoch != _epoch) return;
      if (state is TripLoading) {
        _state.value = TripFailed(_failureOf(e));
      } else if (++_missedPolls >= maxMissedPolls) {
        _isOffline.value = true;
      }
    } finally {
      if (epoch == _epoch) _isPolling = false;
    }
  }

  TripLoadFailure _failureOf(Object error) =>
      error is ApiException && error.statusCode == 404 ? TripLoadFailure.notFound : TripLoadFailure.connection;

  void _accept(Trip incoming, int seq) {
    if (seq <= _applied) return;
    final current = trip;
    if (current != null && TripStatus.advance(current.status, incoming.status) != incoming.status) return;
    _applied = seq;
    _state.value = TripState.of(incoming);
    if (incoming.status.isTerminal) {
      _poller?.cancel();
      _poller = null;
    }
  }

  void _acceptFresh(Trip incoming) => _accept(incoming, ++_seq);

  void applyServerTrip(Trip trip) => _acceptFresh(trip);

  Future<void> pollNow() async {
    while (_isPolling) {
      await Future<void>.delayed(refreshWait);
    }
    await _poll();
  }

  void announce(TripNotice notice) {
    _notice.value = notice;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(noticeDuration, () => _notice.value = null);
  }

  Future<Trip?> loadActive() async {
    try {
      final response = await _api.get(MockEndpoints.activeTrip, suppressErrorToast: true);
      final data = (response.data as Map)['data'];
      if (data == null) return null;
      return Trip.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      log('loadActive failed: $e');
      return null;
    }
  }

  Future<bool> confirmDetails() => _act(isConfirmingDetails, MockEndpoints.liveTripConfirmDetailsOf);

  Future<bool> refreshPin() => _act(isRefreshingPin, MockEndpoints.liveTripPinRefreshOf);

  Future<bool> completeRide() => _act(isCompleting, MockEndpoints.liveTripCompleteOf);

  Future<bool> reportIssue(Iterable<TripIssue> issues) {
    if (issues.isEmpty) return Future.value(false);
    return _act(
      isReporting,
      MockEndpoints.liveTripReportOf,
      data: {
        'reasons': [for (final issue in issues) issue.code],
      },
    );
  }

  Future<bool> _act(RxBool flag, String Function(String id) endpoint, {Map<String, dynamic>? data}) async {
    final id = _tripId;
    if (id == null || flag.value) return false;
    flag.value = true;
    final epoch = _epoch;
    try {
      final response = await _api.post(endpoint(id), data: data, suppressErrorToast: true);
      if (epoch != _epoch) return false;
      _acceptFresh(Trip.fromJson(_dataOf(response.data)));
      return true;
    } catch (e) {
      log('trip action failed: $e');
      if (epoch == _epoch) {
        Toast.error(_messageOf(e));
        unawaited(_poll());
      }
      return false;
    } finally {
      flag.value = false;
    }
  }

  Future<String?> startCall() async {
    final id = _tripId;
    if (id == null || isCalling.value) return null;
    isCalling.value = true;
    try {
      final response = await _api.post(MockEndpoints.liveTripCallOf(id), suppressErrorToast: true);
      return _dataOf(response.data)['maskedNumber'] as String?;
    } catch (e) {
      log('startCall failed: $e');
      return null;
    } finally {
      isCalling.value = false;
    }
  }

  Future<void> openChat() async {
    if (_tripId == null) return;
    _isChatOpen.value = true;
    chatStatus.value = messages.isEmpty ? TripChatStatus.loading : TripChatStatus.ready;
    await _pollChat();
    _startChatPolling();
  }

  void closeChat() {
    _isChatOpen.value = false;
    _chatPoller?.cancel();
    _chatPoller = null;
  }

  void _startChatPolling({bool immediate = false}) {
    _chatPoller?.cancel();
    _chatPoller = null;
    if (_tripId == null || !_isForeground || !isChatOpen) return;
    _chatPoller = Timer.periodic(pollInterval, (_) => _pollChat());
    if (immediate) unawaited(_pollChat());
  }

  Future<void> reloadChat() async {
    chatStatus.value = TripChatStatus.loading;
    await _pollChat();
  }

  Future<void> _pollChat() async {
    final id = _tripId;
    if (id == null || _isChatPolling) return;
    _isChatPolling = true;
    final epoch = _epoch;
    try {
      final response = await _api.get(MockEndpoints.liveTripMessagesOf(id), suppressErrorToast: true);
      if (epoch != _epoch || !isChatOpen) return;
      final server = [
        for (final json in _dataOf(response.data)['messages'] as List)
          TripMessage.fromJson(Map<String, dynamic>.from(json as Map)),
      ];
      _mergeServerMessages(server);
      chatStatus.value = TripChatStatus.ready;
    } catch (e) {
      log('chat poll failed: $e');
      if (epoch == _epoch && messages.isEmpty) chatStatus.value = TripChatStatus.failed;
    } finally {
      if (epoch == _epoch) _isChatPolling = false;
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
    final epoch = _epoch;
    try {
      final response = await _api.post(
        MockEndpoints.liveTripMessagesOf(id),
        data: {'body': body, 'clientId': clientId},
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      _replaceByClientId(clientId, TripMessage.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('sendMessage failed: $e');
      if (epoch == _epoch) _markDelivery(clientId, TripMessageDelivery.failed);
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

  String _messageOf(Object error) => error is ApiException ? error.message : genericFailure;

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
