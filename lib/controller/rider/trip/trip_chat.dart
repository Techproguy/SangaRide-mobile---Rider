part of 'trip_controller.dart';

extension TripChat on TripController {
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
    final poller = LivePoller(fetch: _fetchChat, interval: TripController.pollInterval, onParseError: _onParseError);
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
