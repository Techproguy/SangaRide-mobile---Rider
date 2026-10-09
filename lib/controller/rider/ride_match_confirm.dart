part of 'ride_match_controller.dart';

extension RideMatchConfirm on RideMatchController {
  Mutation<ConfirmedTrip> _confirmFor(DriverHold hold) {
    final signature = '${hold.offerId}@${hold.holdExpiresAt.millisecondsSinceEpoch}';
    final existing = _confirmMutation;
    if (existing != null && _confirmSignature == signature) return existing;
    existing?.dispose();
    _confirmSignature = signature;
    final requestId = _requestId;
    return _confirmMutation = Mutation<ConfirmedTrip>(
      intent: IdempotencyIntent.confirmDriver,
      run: (key) async {
        final response = await _api.post(
          AppEndpoints.rideOfferConfirmOf(requestId!, hold.offerId),
          key: key,
          suppressErrorToast: true,
        );
        return ConfirmedTrip.fromJson(response.dataMap);
      },
      reconcile: () => _reconcileConfirm(hold),
    );
  }

  Future<Reconciled<ConfirmedTrip>> _reconcileConfirm(DriverHold hold) async {
    final response = await _api.get(AppEndpoints.activeTrip, suppressErrorToast: true);
    final tripId = JsonReader.of((response.data as Map)['data']).strOrNull('id');
    if (tripId == null) return const ReconciledNotDone();
    return ReconciledDone(ConfirmedTrip(tripId: tripId, etaMinutes: hold.etaMinutes, driver: hold.driver));
  }

  Future<bool> confirm() async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchHolding || current.isConfirming) return false;
    final epoch = _epoch.current;
    final mutation = _confirmFor(current.hold);
    _state.value = MatchHolding(current.rows, hold: current.hold, isConfirming: true);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return false;
    switch (result) {
      case MutationDone<ConfirmedTrip>(:final value):
        _requestId = null;
        _persist();
        _state.value = MatchConfirmed(value);
        _refreshRestore();
        return true;
      case MutationRejected<ConfirmedTrip>(:final error):
        mutation.reset();
        _backToOffers(error, current.hold.offerId);
      case MutationFailed<ConfirmedTrip>(:final error):
        _state.value = MatchHolding(current.rows, hold: current.hold);
        SangaToast.show(OfferUnavailableReason.of(error).message, tone: SangaToastTone.error);
      case MutationUnknown<ConfirmedTrip>() ||
          MutationIdle<ConfirmedTrip>() ||
          MutationRunning<ConfirmedTrip>() ||
          MutationChecking<ConfirmedTrip>():
        _state.value = MatchHolding(current.rows, hold: current.hold);
        SangaToast.show(
          'We couldn’t confirm that. Tap confirm again. We won’t book it twice.',
          tone: SangaToastTone.warning,
        );
        _refreshRestore();
    }
    return false;
  }
}
