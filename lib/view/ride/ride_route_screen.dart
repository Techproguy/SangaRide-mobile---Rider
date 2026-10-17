import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride/view/ride/widgets/route_panel.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/map/sanga_map.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideRouteScreen extends StatefulWidget {
  const RideRouteScreen({super.key, this.returnsOnConfirm = false});

  final bool returnsOnConfirm;

  @override
  State<RideRouteScreen> createState() => _RideRouteScreenState();
}

class _RideRouteScreenState extends State<RideRouteScreen> {
  static const double _topInset = 120;
  static const Duration _reframeDelay = Duration(milliseconds: 180);

  final _ride = Get.find<RideRequestController>();
  final _home = Get.find<RiderHomeController>();
  final _camera = MapCamera();
  final _routeLines = SangaRouteLines(id: 'route');
  Set<Marker> _markers = const {};
  Worker? _currentPlaceWorker;
  Timer? _frameTimer;
  int _drawRequest = 0;
  SangaRoute? _framedRoute;

  @override
  void initState() {
    super.initState();
    _currentPlaceWorker = ever(_home.currentPlaceObs, (_) {
      if (_ride.pickup == null) _draw();
    });
    _routeLines.addListener(_frameRoadRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _draw());
  }

  void _frameRoadRoute() {
    final route = _routeLines.route;
    if (route == null || route.isEstimate || identical(route, _framedRoute)) return;
    _framedRoute = route;
    _frame();
  }

  @override
  void dispose() {
    _currentPlaceWorker?.dispose();
    _frameTimer?.cancel();
    _routeLines
      ..removeListener(_frameRoadRoute)
      ..dispose();
    super.dispose();
  }

  void _onSheetHeight(double height) {
    final inset = EdgeInsets.only(top: _topInset, bottom: height);
    if (inset == _camera.visibleInsets) return;
    _camera.visibleInsets = inset;
    _frameTimer?.cancel();
    _frameTimer = Timer(_reframeDelay, _frame);
  }

  List<LatLng> get _framePoints {
    final road = _routeLines.route;
    final points = [..._ride.routePoints, if (road != null && !road.isEstimate) ...road.points];
    final current = _home.currentPlace?.coordinates;
    if (_ride.pickup == null && current != null) return [current, ...points];
    return points;
  }

  void _frame() => _camera.fitBounds(_framePoints);

  Future<void> _draw() async {
    final request = ++_drawRequest;
    final markers = await _buildMarkers();
    if (!mounted || request != _drawRequest) return;
    setState(() => _markers = markers);
    _routeLines.show(_ride.routePoints);
    _frame();
  }

  Future<Set<Marker>> _buildMarkers() async {
    final pickup = _ride.pickup;
    final current = _home.currentPlace;
    final dropoff = _ride.dropoff;
    return {
      if (pickup?.coordinates case final position?)
        await PlaceMarker.marker(
          id: 'pickup',
          kind: PlaceMarkerKind.pickup,
          position: position,
          title: pickup!.name,
          subtitle: 'Pick up point',
        )
      else if (current?.coordinates case final position?)
        await PlaceMarker.marker(
          id: 'current',
          kind: PlaceMarkerKind.current,
          position: position,
          title: current!.name,
          subtitle: 'current location',
        ),
      for (final (index, stop) in _ride.stops.indexed)
        if (stop.coordinates case final position?)
          await PlaceMarker.marker(
            id: 'stop_$index',
            kind: PlaceMarkerKind.stop,
            position: position,
            title: stop.name,
            subtitle: 'Stop ${index + 1}',
          ),
      if (dropoff?.coordinates case final position?)
        await PlaceMarker.marker(
          id: 'dropoff',
          kind: PlaceMarkerKind.dropoff,
          position: position,
          title: dropoff!.name,
          subtitle: 'Drop off point',
        ),
    };
  }

  Future<void> _edit(RouteEdit edit) async {
    final isDelivery = _ride.tripType == TripType.delivery;
    final (kind, hint) = switch (edit.point) {
      RoutePoint.pickup => (
        SangaStopKind.pickup,
        isDelivery ? 'Where should we collect it?' : 'Where should we pick you up?',
      ),
      RoutePoint.stop => (SangaStopKind.stop, 'Where should we stop?'),
      RoutePoint.dropoff => (SangaStopKind.dropoff, isDelivery ? 'Where is it going?' : 'Where are you going?'),
    };
    final place = await PlaceSearchSheet.show(
      context,
      kind: kind,
      hintText: hint,
      origin: _ride.pickup?.coordinates ?? _home.currentPlace?.coordinates,
      onPick: (place) => _ride.applyRouteEdit(edit, place),
    );
    if (place == null || !mounted) return;
    if (edit.point != RoutePoint.pickup) _home.rememberPlace(place);
    setState(() {});
    _draw();
  }

  void _confirm() {
    if (widget.returnsOnConfirm) {
      context.pop();
    } else {
      context.push(BookingRoutes.afterRoute(_ride.tripType));
    }
  }

  void _removeStop(int index) {
    _ride.removeStopAt(index);
    setState(() {});
    _draw();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _routeLines,
                  builder: (context, _) => SangaMap(
                    camera: _camera,
                    followsUser: false,
                    extraMarkers: _markers,
                    extraPolylines: _routeLines.polylines,
                    onCameraMove: (position) => _routeLines.updateZoom(position.zoom),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SangaMapButton.back(onPressed: context.pop),
                  ),
                ),
              ),
              Positioned.fill(
                child: SangaMapSheet(
                  onVisibleHeightChanged: _onSheetHeight,
                  child: RoutePanel(
                    pickup: _ride.pickup,
                    stops: _ride.stops,
                    dropoff: _ride.dropoff,
                    canAddStop: _ride.canAddStop,
                    onEdit: _edit,
                    onRemoveStop: _removeStop,
                    onConfirm: _ride.hasRoute ? _confirm : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
