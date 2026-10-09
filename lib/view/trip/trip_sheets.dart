part of 'trip_screen.dart';

const EdgeInsets _sheetPadding = EdgeInsets.all(SangaSpacing.gutter);
const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

extension _TripSheets on _TripScreenState {
  Future<void> _present({
    required WidgetBuilder builder,
    bool isDismissible = true,
    EdgeInsets padding = _sheetPadding,
  }) async {
    _closeSheet();
    if (!mounted) return;
    await showSangaSheet<void>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      padding: padding,
      builder: builder,
    );
  }

  void _openDetailsCheck() {
    final trip = _trip.trip;
    if (trip == null) return;
    unawaited(
      _present(
        builder: (_) => Obx(
          () => DetailsCheckSheet(
            trip: trip,
            unreadCount: _trip.unreadCount,
            isConfirming: _trip.isConfirmingDetails.value,
            onCall: () => _call(trip),
            onMessage: _openChat,
            onConfirm: _trip.confirmDetails,
            onReport: _openReport,
          ),
        ),
      ),
    );
  }

  Future<void> _showPin(Trip initial) {
    var latest = initial;
    return _present(
      builder: (_) => Obx(() {
        if (_trip.state case TripVerifying(:final trip)) latest = trip;
        return PinSheet(
          trip: latest,
          isRefreshing: _trip.isRefreshingPin.value,
          onRefresh: _trip.refreshPin,
          onExpired: () => unawaited(_trip.pollNow()),
        );
      }),
    );
  }

  void _openReport() {
    unawaited(
      _present(
        builder: (_) => Obx(
          () => ReportSheet(isReporting: _trip.isReporting.value, onReport: _trip.reportIssue, onDismiss: _closeSheet),
        ),
      ),
    );
  }

  Future<void> _showAuthenticated() {
    return _present(
      isDismissible: false,
      padding: _statusPadding,
      builder: (_) => PopScope(
        canPop: false,
        child: SangaStatusContent(
          status: SangaStatus.success,
          title: 'Ride authenticated',
          message: 'Your driver confirmed your PIN.',
          action: SangaButton.primary(label: 'Make payment', onPressed: _makePayment),
        ),
      ),
    );
  }

  Future<void> _startPickupConfirmation(Trip trip) async {
    _closeSheet();
    if (trip.deliveryPhase != DeliveryPhase.confirmPickup || !mounted) return;
    await context.push(DeliveryLiveRoutes.confirmPickupOf(trip.id));
  }

  Future<void> _showPickedUp() async {
    if (!mounted) return;
    _closeSheet();
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      _trip.announce(TripNotice.packagePickedUp);
      return;
    }
    await _present(
      isDismissible: false,
      padding: _statusPadding,
      builder: (_) => PopScope(
        canPop: false,
        child: SangaStatusContent(
          status: SangaStatus.success,
          title: 'Package picked up',
          message: 'Your driver has your package. Make your payment and they’ll be on their way.',
          action: SangaButton.primary(label: 'Make payment', onPressed: _makePayment),
        ),
      ),
    );
  }

  Future<void> _showRefused(DeliveryRefusal refusal) {
    return _present(
      isDismissible: false,
      padding: _statusPadding,
      builder: (_) => PopScope(
        canPop: false,
        child: DeliveryRefusedContent(refusal: refusal, onHome: _goHome),
      ),
    );
  }

  Future<void> _showCancelled(Trip trip, TripCancelReason reason) {
    return _present(
      isDismissible: false,
      padding: _statusPadding,
      builder: (_) => PopScope(
        canPop: false,
        child: reason.offersRematch && !trip.isDelivery
            ? Obx(() => _rematchContent(trip, reason))
            : SangaStatusContent(
                status: reason.didNotHappen ? SangaStatus.failure : SangaStatus.caution,
                title: reason.title,
                message: trip.cancellationMessage ?? reason.message,
                action: SangaButton.primary(label: CommonCopy.backToHome, onPressed: _goHome),
              ),
      ),
    );
  }

  Widget _rematchContent(Trip trip, TripCancelReason reason) {
    return SangaStatusContent(
      status: SangaStatus.failure,
      title: reason.title,
      message: trip.cancellationMessage ?? reason.message,
      action: SangaButton.primary(
        label: 'Find another driver',
        isLoading: _ride.isRestoring,
        onPressed: () => unawaited(_findAnotherDriver(trip)),
      ),
      secondary: SangaButton.muted(label: CommonCopy.backToHome, onPressed: _goHome),
    );
  }

  Future<void> _findAnotherDriver(Trip trip) async {
    final isReady = await _ride.restoreRoute(
      pickup: trip.pickup.toPlace(),
      stops: [for (final stop in trip.stops) stop.toPlace()],
      dropoff: trip.dropoff.toPlace(),
      category: trip.rideType,
    );
    if (!mounted) return;
    if (!isReady) return SangaToast.show('We couldn’t set that up. Give it another go.', tone: SangaToastTone.error);
    _isLeaving = true;
    _closeSheet();
    await startMatching(context);
  }
}
