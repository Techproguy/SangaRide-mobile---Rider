part of 'trip_payment_controller.dart';

extension TripPaymentCash on TripPaymentController {
  CashWaitLink _cashLinkOf(TripPayment payment) {
    final deadline = payment.cashWaitExpiresAt;
    if (deadline != null && !deadline.isAfter(DateTime.now())) return CashWaitLink.timedOut;
    return _poller?.link.value == LinkState.lost ? CashWaitLink.offline : CashWaitLink.live;
  }

  void _scheduleCashDeadline(TripPayment payment) {
    _cashTimer?.cancel();
    _cashTimer = null;
    final deadline = payment.cashWaitExpiresAt;
    if (deadline == null) return;
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) return;
    _cashTimer = Timer(left, () {
      final current = state;
      if (current is PaymentAwaitingDriver) _state.value = current.withLink(CashWaitLink.timedOut);
      unawaited(_poller?.refreshNow());
    });
  }

  void chooseCashInstead() {
    final current = state;
    if (current is! PaymentLoaded || isProcessing || current is PaymentPaid || current is PaymentUnconfirmed) return;
    if (!current.payment.allowedMethods.contains(PaymentMethod.cash)) return;
    _state.value = PaymentChoosing(current.payment, selected: PaymentMethod.cash);
  }

  Future<void> payCash() async {
    final current = state;
    if (current is! PaymentChoosing || current.selected != PaymentMethod.cash) return;
    await _submit(current.payment, const PaymentRequest.cash(), signature: 'cash');
  }

  Future<void> cancelCash() async {
    final id = _tripId;
    final current = state;
    if (id == null || current is! PaymentAwaitingDriver) return;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
    final epoch = _invalidate();
    final mutation = _cancelCashMutation ??= Mutation<TripPayment>(
      intent: IdempotencyIntent.tripPayCancel,
      run: (key) async {
        final response = await _api.post(AppEndpoints.tripPaymentCancelOf(id), key: key, suppressErrorToast: true);
        return TripPayment.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () async {
        final fresh = await _fetchPayment(id, profile: RequestProfile.interactive);
        return fresh.status == PaymentStatus.awaitingDriver ? const ReconciledNotDone() : ReconciledDone(fresh);
      },
    );
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return;
    switch (result) {
      case MutationDone<TripPayment>(:final value):
        _cancelCashMutation?.dispose();
        _cancelCashMutation = null;
        _apply(value, epoch);
      case MutationRejected<TripPayment>(:final error):
        _cancelCashMutation?.dispose();
        _cancelCashMutation = null;
        if (error.code == ServerCode.alreadyPaid) {
          unawaited(_load());
        } else {
          LiveProblem.toast(error);
          _apply(current.payment, epoch);
        }
      case MutationFailed<TripPayment>(:final error):
        LiveProblem.toast(error);
        _state.value = current;
        _startPolling(epoch);
      case MutationUnknown<TripPayment>():
        SangaToast.show(LiveProblem.checking, tone: SangaToastTone.warning);
        _state.value = current;
        _startPolling(epoch);
      default:
        break;
    }
  }
}
