import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class SupportChatController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final Rx<ChatState> _state = Rx<ChatState>(const ChatConnecting());

  Timer? _poll;
  int _pollingEpoch = -1;
  int _clientSerial = 0;
  int _epoch = 0;

  ChatState get state => _state.value;

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> open({String? ticketId, String? tripId}) async {
    _poll?.cancel();
    final epoch = ++_epoch;
    _state.value = const ChatConnecting();
    try {
      final response = await _api.post(
        SupportEndpoints.chats,
        data: {'ticketId': ticketId, 'tripId': tripId},
        options: quietOptions,
      );
      if (epoch != _epoch) return;
      _state.value = ChatLive(SupportChat.fromJson(dataOf(response)), const []);
      await _fetch(epoch);
    } catch (error) {
      log('chat open failed: $error');
      if (epoch == _epoch) _state.value = ChatUnavailable(_problemOf(error));
    }
  }

  void close() {
    _epoch++;
    _poll?.cancel();
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
        options: quietOptions,
      );
      _poll?.cancel();
      final current = _live ?? live;
      _state.value = current.copyWith(chat: SupportChat.fromJson(dataOf(response)), isEnding: false);
      await _fetch(_epoch, reschedule: false);
      return true;
    } catch (error) {
      log('chat end failed: $error');
      _state.value = (_live ?? live).copyWith(isEnding: false, problem: _problemOf(error));
      return false;
    }
  }

  ChatLive? get _live => switch (_state.value) {
    final ChatLive live => live,
    _ => null,
  };

  Future<void> _deliver(ChatMessage pending) async {
    final live = _live;
    final clientId = pending.clientId;
    if (live == null || clientId == null) return;
    try {
      final response = await _api.post(
        SupportEndpoints.of(SupportEndpoints.chatMessages, live.chat.id),
        data: {'text': pending.text, 'clientId': clientId},
        options: quietOptions,
      );
      final sent = ChatMessage.fromJson(dataOf(response));
      _replace(clientId, sent);
    } catch (error) {
      log('chat send failed: $error');
      if (error is ApiException && error.code == 'chat_ended') {
        final current = _live;
        if (current != null) _state.value = current.copyWith(problem: SupportProblem.chatEnded);
      }
      _replace(clientId, pending.withDelivery(ChatDelivery.failed));
    }
  }

  void _replace(String clientId, ChatMessage message) {
    final live = _live;
    if (live == null) return;
    final exists = live.messages.any((existing) => existing.clientId == clientId);
    _state.value = live.copyWith(
      messages: [
        for (final existing in live.messages)
          if (existing.clientId == clientId) message else existing,
        if (!exists) message,
      ],
    );
  }

  Future<void> _fetch(int epoch, {bool reschedule = true}) async {
    if (_pollingEpoch == epoch) return;
    _pollingEpoch = epoch;
    try {
      final live = _live;
      if (live == null || epoch != _epoch) return;
      final lastServerId = live.messages
          .where((message) => message.delivery != ChatDelivery.sending && message.delivery != ChatDelivery.failed)
          .lastOrNull
          ?.id;
      final response = await _api.get(
        SupportEndpoints.of(SupportEndpoints.chatMessages, live.chat.id),
        queryParameters: {'after': ?lastServerId},
        options: quietOptions,
      );
      if (epoch != _epoch) return;
      final update = ChatUpdate.fromJson(dataOf(response));
      final current = _live ?? live;
      final known = {for (final message in current.messages) message.id};
      final clientIds = {for (final message in current.messages) ?message.clientId};
      final fresh = [
        for (final message in update.messages)
          if (!known.contains(message.id) && !(message.isMine && clientIds.contains(message.clientId))) message,
      ];
      final merged = [...current.messages, ...fresh]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _state.value = current.copyWith(chat: update.chat, messages: merged);
      if (update.chat.status == ChatStatus.ended) return;
    } catch (error) {
      log('chat poll failed: $error');
    } finally {
      if (_pollingEpoch == epoch) _pollingEpoch = -1;
    }
    if (reschedule && epoch == _epoch) _poll = Timer(_pollEvery, () => _fetch(epoch));
  }

  SupportProblem _problemOf(Object error) =>
      error is ApiException ? SupportProblem.fromCode(error.code) : SupportProblem.connection;
}
