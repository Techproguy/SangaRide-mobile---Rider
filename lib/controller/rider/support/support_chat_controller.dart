import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SupportChatController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final Rx<ChatState> _state = Rx<ChatState>(const ChatConnecting());
  final Rx<LinkState> _link = Rx<LinkState>(LinkState.live);

  LivePoller? _poller;
  Mutation<SupportChat>? _opening;
  String? _openingSignature;
  String? _cursor;
  int _clientSerial = 0;
  final Epoch _epoch = Epoch();

  ChatState get state => _state.value;

  Rx<LinkState> get linkRx => _link;

  @override
  void onClose() {
    _stopPolling();
    _opening?.dispose();
    super.onClose();
  }

  Future<void> open({String? ticketId, String? tripId}) async {
    _stopPolling();
    final epoch = _epoch.next();
    _cursor = null;
    _state.value = const ChatConnecting();
    final mutation = _openingFor(ticketId, tripId);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return;
    switch (result) {
      case MutationDone<SupportChat>(:final value):
        _state.value = ChatLive(value, const []);
        _startPolling(epoch);
      case MutationRejected<SupportChat>(:final error):
        mutation.reset();
        _state.value = ChatUnavailable(SupportProblem.of(error));
      case MutationFailed<SupportChat>(:final error):
        mutation.reset(keepKey: true);
        _state.value = ChatUnavailable(SupportProblem.of(error));
      case MutationUnknown<SupportChat>():
        mutation.reset(keepKey: true);
        _state.value = const ChatUnavailable(SupportProblem.unconfirmed);
      case MutationIdle<SupportChat>() || MutationRunning<SupportChat>() || MutationChecking<SupportChat>():
        break;
    }
  }

  void close() {
    _epoch.next();
    _stopPolling();
  }

  Future<void> send(String text) async {
    final live = _live;
    final trimmed = text.trim();
    if (live == null || trimmed.isEmpty || live.chat.status == ChatStatus.ended) return;
    final pending = ChatMessage.pending(
      clientId: 'c_${DateTime.now().microsecondsSinceEpoch}_${_clientSerial++}',
      text: trimmed,
    );
    _state.value = live.copyWith(messages: [...live.messages, pending], clearProblem: true);
    await _deliver(pending);
  }

  Future<void> retry(String clientId) async {
    final live = _live;
    final failed = live?.messages.where((message) => message.clientId == clientId).firstOrNull;
    if (live == null || failed == null) return;
    _replace(clientId, failed.withDelivery(ChatDelivery.sending));
    await _deliver(failed);
  }

  Future<bool> end() async {
    final live = _live;
    if (live == null || live.isEnding) return false;
    _state.value = live.copyWith(isEnding: true);
    try {
      final response = await _api.post(
        SupportEndpoints.of(SupportEndpoints.chatEnd, live.chat.id),
        key: IdempotencyKey(IdempotencyIntent.chatEndKey(live.chat.id)),
        suppressErrorToast: true,
      );
      _stopPolling();
      final current = _live ?? live;
      _state.value = current.copyWith(chat: SupportChat.fromJson(response.dataMapOrEmpty), isEnding: false);
      await _fetch();
      return true;
    } on Object catch (error) {
      _state.value = (_live ?? live).copyWith(isEnding: false, problem: SupportProblem.of(error));
      return false;
    }
  }

  Mutation<SupportChat> _openingFor(String? ticketId, String? tripId) {
    final signature = '${ticketId ?? ''}|${tripId ?? ''}';
    final existing = _opening;
    if (existing != null && _openingSignature == signature && !existing.isBusy) {
      return existing..reset(keepKey: existing.state.value is! MutationDone<SupportChat>);
    }
    existing?.dispose();
    _openingSignature = signature;
    return _opening = Mutation<SupportChat>(
      intent: IdempotencyIntent.supportChat,
      run: (key) async {
        final response = await _api.post(
          SupportEndpoints.chats,
          data: {'ticketId': ticketId, 'tripId': tripId},
          key: key,
          suppressErrorToast: true,
        );
        return SupportChat.fromJson(response.dataMapOrEmpty);
      },
    );
  }

  ChatLive? get _live => switch (_state.value) {
    final ChatLive live => live,
    _ => null,
  };

  Future<void> _deliver(ChatMessage pending) async {
    final live = _live;
    final clientId = pending.clientId;
    if (live == null || clientId == null) return;
    if (ConnectionMonitor.current?.isOnline == false) {
      _replace(clientId, pending.withDelivery(ChatDelivery.failed));
      return;
    }
    try {
      final response = await _api.post(
        SupportEndpoints.of(SupportEndpoints.chatMessages, live.chat.id),
        data: {'text': pending.text, 'clientId': clientId},
        key: IdempotencyKey(IdempotencyIntent.chatMessageKey(clientId)),
        suppressErrorToast: true,
      );
      _confirm(clientId, ChatMessage.fromJson(response.dataMapOrEmpty));
    } on Object catch (error) {
      _replace(clientId, pending.withDelivery(ChatDelivery.failed));
      if (error is ApiException && error.code == ServerCode.chatEnded) {
        final current = _live;
        if (current != null) _state.value = current.copyWith(problem: SupportProblem.chatEnded);
        await _fetch();
      }
    }
  }

  void _confirm(String clientId, ChatMessage sent) {
    final live = _live;
    if (live == null) return;
    final withoutLocal = [
      for (final message in live.messages)
        if (message.clientId != clientId) message,
    ];
    final alreadyKnown = withoutLocal.any((message) => message.id == sent.id);
    final confirmed = [
      for (final message in withoutLocal)
        if (_isConfirmed(message)) message,
      if (!alreadyKnown) sent,
    ];
    final outbox = [
      for (final message in withoutLocal)
        if (!_isConfirmed(message)) message,
    ];
    _state.value = live.copyWith(messages: [...confirmed, ...outbox]);
  }

  void _replace(String clientId, ChatMessage message) {
    final live = _live;
    if (live == null) return;
    _state.value = live.copyWith(
      messages: [
        for (final existing in live.messages)
          if (existing.clientId == clientId) message else existing,
      ],
    );
  }

  bool _isConfirmed(ChatMessage message) =>
      message.delivery != ChatDelivery.sending && message.delivery != ChatDelivery.failed;

  void _startPolling(int epoch) {
    _stopPolling();
    final poller = LivePoller(fetch: () => _fetchFor(epoch), interval: _pollEvery);
    poller.link.addListener(() => _link.value = poller.link.value);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    final poller = _poller;
    _poller = null;
    _link.value = LinkState.live;
    if (poller != null) Future<void>.microtask(poller.dispose);
  }

  Future<void> _fetch() => _fetchFor(_epoch.current);

  Future<void> _fetchFor(int epoch) async {
    final live = _live;
    if (live == null || !_epoch.isCurrent(epoch)) return;
    final response = await _api.get(
      SupportEndpoints.of(SupportEndpoints.chatMessages, live.chat.id),
      queryParameters: {'after': ?_cursor},
      suppressErrorToast: true,
    );
    if (!_epoch.isCurrent(epoch)) return;
    final update = ChatUpdate.fromJson(response.dataMapOrEmpty);
    final cursor = update.cursor;
    if (cursor != null) _cursor = cursor;
    _merge(update);
    if (update.chat.status == ChatStatus.ended) _stopPolling();
  }

  void _merge(ChatUpdate update) {
    final current = _live;
    if (current == null) return;
    final known = {
      for (final message in current.messages)
        if (_isConfirmed(message)) message.id,
    };
    final outboxByClientId = {
      for (final message in current.messages)
        if (!_isConfirmed(message) && message.clientId != null) message.clientId!: message,
    };
    final fresh = <ChatMessage>[];
    final answered = <String>{};
    for (final message in update.messages) {
      if (known.contains(message.id)) continue;
      fresh.add(message);
      final clientId = message.clientId;
      if (message.isMine && clientId != null && outboxByClientId.containsKey(clientId)) answered.add(clientId);
    }
    final confirmed = [
      for (final message in current.messages)
        if (_isConfirmed(message)) message,
      ...fresh,
    ];
    final outbox = [
      for (final message in current.messages)
        if (!_isConfirmed(message) && !answered.contains(message.clientId)) message,
    ];
    _state.value = current.copyWith(chat: update.chat, messages: [...confirmed, ...outbox]);
  }
}
