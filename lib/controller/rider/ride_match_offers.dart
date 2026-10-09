part of 'ride_match_controller.dart';

extension RideMatchOffers on RideMatchController {
  Future<void> loadOffers() async {
    final id = _requestId;
    if (id == null || (state is! MatchOffersReady && state is! MatchOffersFailed)) return;
    final epoch = _epoch.current;
    _state.value = const MatchOffersLoading();
    try {
      final rows = await _fetchOffers(id);
      if (!_epoch.isCurrent(epoch)) return;
      _state.value = MatchOffersListed(rows);
    } catch (e) {
      log('loadOffers failed: $e');
      if (_epoch.isCurrent(epoch)) _state.value = MatchOffersFailed(problem: RideLoadProblem.of(e));
    }
  }

  Future<List<OfferRow>> _fetchOffers(String id) async {
    final response = await _api.get(AppEndpoints.rideRequestOffersOf(id), suppressErrorToast: true);
    return JsonReader.of(response.dataMap).listOf('offers', (item) => OfferRow(DriverOffer.fromJson(item)));
  }

  void startOffersRefresh() {
    if (_offersPoller != null) return;
    final epoch = _epoch.current;
    _offersPoller = LivePoller(
      fetch: () => _refreshOffers(epoch),
      interval: RideMatchController.offersRefreshInterval,
      onParseError: (error, _) => log('offers unreadable: $error'),
    )..start();
  }

  void stopOffersRefresh() {
    _offersPoller?.dispose();
    _offersPoller = null;
  }

  Future<void> _refreshOffers(int epoch) async {
    final id = _requestId;
    if (id == null || !_epoch.isCurrent(epoch) || !_canMergeOffers(state)) return;
    final fresh = await _fetchOffers(id);
    final latest = state;
    if (!_epoch.isCurrent(epoch) || latest is! MatchBrowsing || !_canMergeOffers(latest)) return;
    _state.value = latest.withRows(_merged(latest.rows, fresh));
  }

  bool _canMergeOffers(RideMatchState current) => switch (current) {
    MatchOffersListed(:final acceptingOfferId) => acceptingOfferId == null,
    MatchHolding(:final isConfirming) => !isConfirming,
    _ => false,
  };

  List<OfferRow> _merged(List<OfferRow> current, List<OfferRow> fresh) {
    final leaving = {
      for (final row in current)
        if (row.isLeaving) row.offer.id,
    };
    return [
      for (final row in fresh)
        if (!leaving.contains(row.offer.id)) row,
    ];
  }

  Future<void> ignore(DriverOffer offer) async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchOffersListed || current.acceptingOfferId != null) return;
    if (current.rows.any((row) => row.offer.id == offer.id && row.isLeaving)) return;
    final epoch = _epoch.current;
    _state.value = current.withRows([for (final row in current.rows) row.offer.id == offer.id ? row.asLeaving() : row]);
    unawaited(_sendIgnore(id, offer.id));
    await Future<void>.delayed(RideMatchController.rowExitDuration);
    final latest = state;
    if (!_epoch.isCurrent(epoch) || latest is! MatchBrowsing) return;
    _state.value = latest.withRows([
      for (final row in latest.rows)
        if (row.offer.id != offer.id) row,
    ]);
  }

  Future<void> _sendIgnore(String id, String offerId) async {
    final key = IdempotencyKey.newFor(IdempotencyIntent.ignoreOffer);
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _api.post(AppEndpoints.rideOfferIgnoreOf(id, offerId), key: key, suppressErrorToast: true);
        return;
      } catch (e) {
        log('ignore failed: $e');
        await Future<void>.delayed(RideMatchController.retryDelay);
      }
    }
    if (_requestId == id) unawaited(_refreshOffers(_epoch.current));
  }

  Future<bool> hold(DriverOffer offer) async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchOffersListed || current.acceptingOfferId != null || !offer.isAvailable) {
      return false;
    }
    final epoch = _epoch.current;
    _state.value = MatchOffersListed(current.rows, acceptingOfferId: offer.id);
    try {
      final response = await _api.post(
        AppEndpoints.rideOfferHoldOf(id, offer.id),
        key: IdempotencyKey.newFor(IdempotencyIntent.holdOffer),
        suppressErrorToast: true,
      );
      if (!_epoch.isCurrent(epoch)) return false;
      _state.value = MatchHolding(
        current.rows,
        hold: DriverHold.fromJson(response.dataMap, etaMinutes: offer.etaMinutes),
      );
      return true;
    } catch (e) {
      log('hold failed: $e');
      if (_epoch.isCurrent(epoch)) _backToOffers(e, offer.id);
      return false;
    }
  }

  Future<void> releaseHold() async {
    final id = _requestId;
    final current = state;
    if (id == null || current is! MatchHolding || current.isConfirming) return;
    _state.value = MatchOffersListed(current.rows);
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _api.delete(AppEndpoints.rideRequestHoldOf(id), suppressErrorToast: true);
        return;
      } on ApiException catch (e) {
        if (e.kind == ApiFailureKind.rejected) return;
        log('releaseHold failed: $e');
      }
      await Future<void>.delayed(RideMatchController.retryDelay);
    }
    if (_requestId == id) unawaited(_refreshOffers(_epoch.current));
  }

  Future<void> expireHold() async {
    if (state is! MatchHolding) return;
    SangaToast.show(OfferUnavailableReason.holdExpired.message, tone: SangaToastTone.warning);
    await releaseHold();
  }

  void _backToOffers(Object error, String offerId) {
    final current = state;
    if (current is! MatchBrowsing) return;
    final reason = OfferUnavailableReason.of(error);
    _state.value = MatchOffersListed([
      for (final row in current.rows) reason.removesOffer && row.offer.id == offerId ? row.asWithdrawn() : row,
    ]);
    SangaToast.show(reason.message, tone: SangaToastTone.error);
  }
}
