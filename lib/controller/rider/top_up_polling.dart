part of 'top_up_controller.dart';

extension TopUpPolling on TopUpController {
  Future<void> refreshNow() async {
    await _poller?.refreshNow();
  }

  void _startPolling(int epoch, Duration interval) {
    _stopPolling();
    _watchStartedAt = ServerClock.instance.now();
    final poller = LivePoller(fetch: () => _pollOnce(epoch), interval: interval);
    poller.link.addListener(() => _link.value = poller.link.value);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    final poller = _poller;
    _poller = null;
    _link.value = LinkState.live;
    if (poller == null) return;
    Future<void>.microtask(poller.dispose);
  }

  Future<void> _pollOnce(int epoch) async {
    final current = state;
    final id = switch (current) {
      TopUpTransferWatching(:final expectation) || TopUpTransferDelayed(:final expectation) => expectation.id,
      TopUpConfirming(:final topUp) => topUp.id,
      _ => null,
    };
    if (id == null || !_epoch.isCurrent(epoch)) return;
    final TopUp topUp;
    try {
      topUp = await _fetch(id);
    } on ApiException catch (error) {
      if (error.kind != ApiFailureKind.rejected || !_epoch.isCurrent(epoch)) rethrow;
      _stopPolling();
      await _clearSaved();
      _state.value = TopUpFailed(
        TopUpFailure.unknown,
        method: current is TopUpConfirming ? TopUpMethod.card : TopUpMethod.transfer,
      );
      return;
    }
    if (!_epoch.isCurrent(epoch)) return;
    final method = current is TopUpConfirming ? TopUpMethod.card : TopUpMethod.transfer;
    final amount = topUp.amount ?? draft.amount ?? 0;
    if (topUp.status == TopUpStatus.awaitingTransfer) {
      _markDelayedIfDue(current, topUp);
    } else if (topUp.status != TopUpStatus.pending && topUp.status != TopUpStatus.unknown) {
      _stopPolling();
      await _apply(topUp, amount: amount, method: method, epoch: epoch);
    }
  }

  void _markDelayedIfDue(TopUpState current, TopUp topUp) {
    if (current is! TopUpTransferWatching) return;
    final since = topUp.createdAt ?? _watchStartedAt ?? ServerClock.instance.now();
    if (ServerClock.instance.now().difference(since) >= TopUpController.transferDelayedAfter) {
      _state.value = TopUpTransferDelayed(current.expectation);
    }
  }
}
