import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_refused_content.dart';
import 'package:sanga_ride/view/ride/matching/matching_flow.dart';
import 'package:sanga_ride/view/trip/widgets/active_ride_panel.dart';
import 'package:sanga_ride/view/trip/widgets/arrived_panel.dart';
import 'package:sanga_ride/view/trip/widgets/authenticated_panel.dart';
import 'package:sanga_ride/view/trip/widgets/call_driver.dart';
import 'package:sanga_ride/view/trip/widgets/delivery_trip_panel.dart';
import 'package:sanga_ride/view/trip/widgets/details_check_sheet.dart';
import 'package:sanga_ride/view/trip/widgets/en_route_panel.dart';
import 'package:sanga_ride/view/trip/widgets/pin_sheet.dart';
import 'package:sanga_ride/view/trip/widgets/report_sheet.dart';
import 'package:sanga_ride/view/trip/widgets/share_trip.dart';
import 'package:sanga_ride/view/trip/widgets/trip_flight_line.dart';
import 'package:sanga_ride/view/trip/widgets/trip_map.dart';
import 'package:sanga_ride/view/trip/widgets/trip_state_panel.dart';
import 'package:sanga_ride/view/trip/widgets/verifying_panel.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  static const double _topInset = 120;
  static const Duration _reframeDelay = Duration(milliseconds: 180);
  static const EdgeInsets _sheetPadding = EdgeInsets.all(SangaSpacing.gutter);
  static const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
    SangaSpacing.xl,
    SangaSpacing.xxl,
    SangaSpacing.xl,
    SangaSpacing.xl,
  );

  final _trip = Get.find<TripController>();
  final _ride = Get.find<RideRequestController>();
  final _camera = MapCamera();
  final _panelKey = GlobalKey();
  late final Worker _worker;
  TripState _previous = const TripLoading();
  DeliveryPhase? _phase;
  Timer? _reframeTimer;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _worker = ever(_trip.stateRx, _onState);
    unawaited(_trip.open(widget.tripId));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
  }

  @override
  void dispose() {
    _reframeTimer?.cancel();
    _worker.dispose();
    _trip.close(onlyTripId: widget.tripId);
    super.dispose();
  }

  bool _isLive(TripState state) => switch (state) {
    TripEnRoute() ||
    TripArrived() ||
    TripVerifying() ||
    TripAuthenticated() ||
    TripInProgress() ||
    TripAtDropoff() => true,
    _ => false,
  };

  void _onState(TripState next) {
    final previous = _previous;
    final previousPhase = _phase;
    _previous = next;
    _phase = next is TripLoaded ? next.trip.deliveryPhase : null;
    if (!mounted || _isLeaving) return;
    if (next is TripLoaded && _hasRouteChanged(previous, next)) {
      _scheduleReframe();
    }
    switch (next) {
      case TripVerifying(:final trip) when previous is! TripVerifying:
        unawaited(_showPin(trip));
      case TripAuthenticated(:final trip) when previous is! TripAuthenticated:
        unawaited(trip.isDelivery ? _startPickupConfirmation(trip) : _showAuthenticated());
      case TripInProgress() || TripAtDropoff():
        _closeSheet();
      case TripRefused(:final refusal) when previous is! TripRefused:
        _popPagesAbove();
        unawaited(_showRefused(refusal));
      case TripCancelled(:final reason, :final trip)
          when previous is! TripCancelled && reason != TripCancelReason.riderCancelled:
        if (trip.isDelivery) _popPagesAbove();
        unawaited(_showCancelled(trip, reason));
      case TripCompleted(:final trip):
        _leaveForCompletion(trip.id);
      default:
        break;
    }
    if (_phase == DeliveryPhase.payment && previousPhase != DeliveryPhase.payment) unawaited(_showPickedUp());
  }

  bool _hasRouteChanged(TripState previous, TripLoaded next) {
    if (previous is! TripLoaded) return true;
    return previous.trip.status != next.trip.status || previous.trip.stops.length != next.trip.stops.length;
  }

  void _syncPanelInset() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final inset = EdgeInsets.only(top: _topInset, bottom: box.size.height);
    if (inset == _camera.visibleInsets) return;
    _camera.visibleInsets = inset;
    _scheduleReframe();
  }

  void _scheduleReframe() {
    _reframeTimer?.cancel();
    _reframeTimer = Timer(_reframeDelay, _reframe);
  }

  void _reframe() {
    final trip = _trip.trip;
    if (!mounted || trip == null) return;
    unawaited(_camera.fitBounds(tripFramePoints(trip)));
  }

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

  void _closeSheet() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  void _popPagesAbove() {
    if (!mounted) return;
    final own = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == own || route.isFirst);
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
        return PinSheet(trip: latest, isRefreshing: _trip.isRefreshingPin.value, onRefresh: _trip.refreshPin);
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
                status: SangaStatus.failure,
                title: reason.title,
                message: reason.message,
                action: SangaButton.primary(label: 'Back to home', onPressed: _goHome),
              ),
      ),
    );
  }

  Widget _rematchContent(Trip trip, TripCancelReason reason) {
    return SangaStatusContent(
      status: SangaStatus.failure,
      title: reason.title,
      message: reason.message,
      action: SangaButton.primary(
        label: 'Find another driver',
        isLoading: _ride.isRestoring,
        onPressed: () => unawaited(_findAnotherDriver(trip)),
      ),
      secondary: SangaButton.muted(label: 'Back to home', onPressed: _goHome),
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
    if (!isReady) return Toast.error('We couldn’t set that up. Give it another go.');
    _isLeaving = true;
    _closeSheet();
    await startMatching(context);
  }

  Future<void> _makePayment() async {
    _closeSheet();
    await context.push<bool>(TripWrapUpRoutes.payOf(widget.tripId));
  }

  void _leaveForCompletion(String tripId) {
    _isLeaving = true;
    _closeSheet();
    context.go(TripWrapUpRoutes.completeOf(tripId));
  }

  void _goHome() {
    _isLeaving = true;
    context.go(SangaRoutes.home);
  }

  void _openChat() => unawaited(context.push(TripRoutes.chatOf(widget.tripId)));

  void _openAddStops() => unawaited(context.push(TripRoutes.stopsOf(widget.tripId)));

  void _openCancel() => unawaited(context.push(TripRoutes.cancelOf(widget.tripId)));

  void _openSafety() => unawaited(context.push(SafetyRoutes.centreOf(tripId: widget.tripId)));

  void _openDetails() => unawaited(context.push(TripRoutes.detailsOf(widget.tripId)));

  void _openConfirmPickup() => unawaited(context.push(DeliveryLiveRoutes.confirmPickupOf(widget.tripId)));

  void _openDeliveryIssue() => unawaited(context.push(DeliveryLiveRoutes.issueOf(widget.tripId)));

  void _openProof() => unawaited(context.push(DeliveryLiveRoutes.proofOf(widget.tripId)));

  void _call(Trip trip) => unawaited(callDriver(context, firstName: trip.driver.firstName));

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
      TripCancelled(:final reason) => TripEndedPanel(reason: reason, onHome: _goHome),
      TripRefused() => TripEndedPanel(reason: TripCancelReason.packageRefused, onHome: _goHome),
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
              const SangaMapToast(icon: Icons.wifi_off_rounded, message: 'You’re offline. Showing your last update.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _trip.state;
      return PopScope(
        canPop: !_isLive(state),
        child: AnnotatedRegion(
          value: SangaSystemUi.onLight,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: TripMap(trip: _trip.trip, camera: _camera, onMapCreated: _scheduleReframe),
                ),
                _overlays(state),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: AnimatedSize(
                        duration: SangaMotion.morph,
                        curve: SangaMotion.springBlock,
                        alignment: Alignment.bottomCenter,
                        child: SangaMapPanel(key: _panelKey, children: [_flightLine(state), _panel(state)]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
