part of 'trip_screen.dart';

extension _TripPanels on _TripScreenState {
  Widget _flightLine(TripState state) {
    final airport = switch (state) {
      TripEnRoute(:final trip) || TripArrived(:final trip) || TripVerifying(:final trip) => trip.airport,
      TripAuthenticated(:final trip) => trip.airport,
      _ => null,
    };
    if (airport == null) return const SizedBox.shrink();
    return TripFlightLine(
      airport: airport,
      onTap: () => unawaited(context.push(BookingRoutes.flightTrackingOf(widget.tripId, isTrip: true))),
    );
  }

  Widget _deliveryPanel(Trip trip, TripDelivery delivery, DeliveryPhase phase) {
    return DeliveryTripPanel(
      trip: trip,
      delivery: delivery,
      phase: phase,
      unreadCount: _trip.unreadCount,
      actions: DeliveryPanelActions(
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onShare: () => unawaited(shareTrip(trip.id, isDelivery: true)),
        onReportIssue: _openDeliveryIssue,
        onCancel: _openCancel,
        onConfirmDetails: _openDetailsCheck,
        onShowPin: () => unawaited(_showPin(trip)),
        onReportMismatch: _openReport,
        onConfirmPickup: _openConfirmPickup,
        onMakePayment: _makePayment,
        onSeeDetails: _openDetails,
        onSeeProof: _openProof,
      ),
    );
  }

  Widget _panel(TripState state) {
    if (state case TripLoaded(:final trip)) {
      final delivery = trip.delivery;
      final phase = trip.deliveryPhase;
      if (delivery != null && phase != null) return _deliveryPanel(trip, delivery, phase);
    }
    return switch (state) {
      TripLoading() || TripCompleted() => const TripLoadingPanel(),
      TripUpdating(:final trip) => TripUpdatingPanel(
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
      ),
      TripFailed(:final reason) => TripFailedPanel(reason: reason, onRetry: _trip.retryLoad, onHome: _goHome),
      TripEnRoute(:final trip) => EnRoutePanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onAddStops: _openAddStops,
        onCancel: _openCancel,
      ),
      TripArrived(:final trip) => ArrivedPanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onConfirmDetails: _openDetailsCheck,
        onAddStops: _openAddStops,
        onCancel: _openCancel,
      ),
      TripVerifying(:final trip) => VerifyingPanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onShowPin: () => unawaited(_showPin(trip)),
        onReport: _openReport,
        onAddStops: _openAddStops,
        onCancel: _openCancel,
      ),
      TripAuthenticated(:final trip) => AuthenticatedPanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onMakePayment: _makePayment,
      ),
      TripInProgress(:final trip) => ActiveRidePanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onShare: () => unawaited(shareTrip(trip.id)),
        onAddStops: _openAddStops,
        onCancel: _openCancel,
        action: SangaButton.primary(label: 'See details', onPressed: _openDetails),
      ),
      TripAtDropoff(:final trip) => ActiveRidePanel(
        trip: trip,
        unreadCount: _trip.unreadCount,
        onCall: () => _call(trip),
        onMessage: _openChat,
        onSafety: _openSafety,
        onShare: () => unawaited(shareTrip(trip.id)),
        onAddStops: _openAddStops,
        onCancel: _openCancel,
        action: SangaButton.primary(
          label: 'Complete ride',
          isLoading: _trip.isCompleting.value,
          onPressed: _trip.completeRide,
        ),
      ),
      TripCancelled(:final reason, :final trip) => TripEndedPanel(
        reason: reason,
        message: trip.cancellationMessage,
        onHome: _goHome,
      ),
      TripRefused(:final trip) => TripEndedPanel(
        reason: TripCancelReason.packageRefused,
        message: trip.cancellationMessage,
        onHome: _goHome,
      ),
      TripReturned(:final trip) => TripEndedPanel(
        reason: TripCancelReason.deliveryReturned,
        message: trip.cancellationMessage,
        returnFee: trip.returnFee,
        onHome: _goHome,
      ),
    };
  }

  Widget _overlays(TripState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.sm,
          children: [
            if (!_isLive(state)) SangaMapButton.back(onPressed: _goHome),
            if (state is TripArrived)
              SangaMapToast(
                message: 'Your driver has arrived',
                detail: state.trip.isDelivery
                    ? 'Check their details before you hand over the package'
                    : 'Check their details before you share your trip PIN',
              ),
            if (state is TripLoaded && state.trip.deliveryPhase == DeliveryPhase.handedOver)
              const SangaMapToast(message: 'Package handed over to recipient'),
            if (_trip.notice case final notice?) SangaMapToast(message: notice.message),
            if (_trip.isOffline)
              const SangaMapToast(icon: Icons.wifi_off_rounded, message: 'You’re offline. Showing your last update.')
            else if (_trip.isReconnecting)
              const SangaMapToast(icon: Icons.sync_rounded, message: 'Reconnecting. Showing your last update.'),
          ],
        ),
      ),
    );
  }
}
