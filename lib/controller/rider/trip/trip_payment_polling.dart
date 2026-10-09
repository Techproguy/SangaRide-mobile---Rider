part of 'trip_payment_controller.dart';

extension TripPaymentPolling on TripPaymentController {
  void _stopPolling() {
    _cashTimer?.cancel();
    _cashTimer = null;
    _detachLink?.call();
    _detachLink = null;
    _poller?.dispose();
    _poller = null;
  }

  void _startPolling(int epoch) {
    if (_poller != null) return;
    final poller = LivePoller(fetch: () => _pollOnce(epoch), interval: TripPaymentController.pollInterval);
    void mirror() => _onPollLink(poller.link.value);
    poller.link.addListener(mirror);
    _detachLink = () => poller.link.removeListener(mirror);
    _poller = poller;
    poller.start();
  }

  void _onPollLink(LinkState link) {
    final current = state;
    if (current is! PaymentAwaitingDriver || current.link == CashWaitLink.timedOut) return;
    _state.value = current.withLink(link == LinkState.lost ? CashWaitLink.offline : CashWaitLink.live);
  }

  Future<void> _pollOnce(int epoch) async {
    final id = _tripId;
    final current = state;
    final isWaiting = current is PaymentAwaitingDriver || current is PaymentChecking;
    if (id == null || !_epoch.isCurrent(epoch) || !isWaiting) return;
    final fresh = await _fetchPayment(id);
    if (!_epoch.isCurrent(epoch)) return;
    final latest = state;
    if (latest is! PaymentAwaitingDriver && latest is! PaymentChecking) return;
    _apply(fresh, epoch);
  }
}
