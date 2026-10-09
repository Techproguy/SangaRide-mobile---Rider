import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
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

part 'trip_panels.dart';
part 'trip_sheets.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  static const double _topInset = 120;

  static const Duration _reframeDelay = Duration(milliseconds: 180);

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
    TripUpdating() ||
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
      case TripReturned() when previous is! TripReturned:
        _popPagesAbove();
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

  void _closeSheet() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  void _popPagesAbove() {
    if (!mounted) return;
    final own = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == own || route.isFirst);
  }

  Future<void> _makePayment() async {
    _closeSheet();
    await context.push<bool>(TripWrapUpRoutes.payOf(widget.tripId));
  }

  void _leaveForCompletion(String tripId) {
    final wasOnTrip = ModalRoute.of(context)?.isCurrent ?? false;
    _isLeaving = true;
    _closeSheet();
    if (!wasOnTrip) SangaToast.show('Trip complete', tone: SangaToastTone.success);
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
