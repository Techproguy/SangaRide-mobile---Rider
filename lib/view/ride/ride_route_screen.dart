import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/directions_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride/view/ride/widgets/route_panel.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/map/sanga_map.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideRouteScreen extends StatefulWidget {
  const RideRouteScreen({super.key});

  @override
  State<RideRouteScreen> createState() => _RideRouteScreenState();
}

class _RideRouteScreenState extends State<RideRouteScreen> {
  static const double _topInset = 120;
  static const String _routeId = 'route';
  static const int _dashesPerRoute = 40;

  final _ride = Get.find<RideRequestController>();
  final _home = Get.find<RiderHomeController>();
  final _camera = MapCamera();
  final _directions = DirectionsService();
  final _panelKey = GlobalKey();
  Set<Marker> _markers = const {};
  Set<Polyline> _polylines = const {};
  Worker? _currentPlaceWorker;
  int _drawRequest = 0;

  @override
  void initState() {
    super.initState();
    _currentPlaceWorker = ever(_home.currentPlaceObs, (_) {
      if (_ride.pickup == null) _draw();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPanelInset();
      _draw();
    });
  }

  @override
  void dispose() {
    _currentPlaceWorker?.dispose();
    super.dispose();
  }

  void _syncPanelInset() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final inset = EdgeInsets.only(top: _topInset, bottom: box.size.height);
    if (inset == _camera.visibleInsets) return;
    _camera.visibleInsets = inset;
    _frame();
  }

  List<LatLng> get _framePoints {
    final points = _ride.routePoints;
    final current = _home.currentPlace?.coordinates;
    if (_ride.pickup == null && current != null) return [current, ...points];
    return points;
  }

  void _frame() => _camera.fitBounds(_framePoints);

  Future<void> _draw() async {
    final request = ++_drawRequest;
    final markers = await _buildMarkers();
    if (!mounted || request != _drawRequest) return;
    setState(() {
      _markers = markers;
      _polylines = _straightLine();
    });
    _frame();
    final route = await _directions.getRoute(_ride.routePoints);
    if (!mounted || request != _drawRequest || route == null) return;
    setState(() => _polylines = {_polyline(route)});
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

  Set<Polyline> _straightLine() {
    final points = _ride.routePoints;
    if (points.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId(_routeId),
        points: points,
        color: SangaColors.primary,
        width: 4,
        patterns: _dashes(points),
      ),
    };
  }

  List<PatternItem> _dashes(List<LatLng> points) {
    if (!Platform.isIOS) return [PatternItem.dash(18), PatternItem.gap(10)];
    var meters = 0.0;
    for (var i = 1; i < points.length; i++) {
      meters += points[i - 1].metersTo(points[i]);
    }
    return [PatternItem.dash(meters / _dashesPerRoute), PatternItem.gap(meters / (_dashesPerRoute * 2))];
  }

  Polyline _polyline(List<LatLng> points) {
    return Polyline(
      polylineId: const PolylineId(_routeId),
      points: points,
      color: SangaColors.primary,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  Future<void> _edit(RouteEdit edit) async {
    final (kind, hint) = switch (edit.point) {
      RoutePoint.pickup => (SangaStopKind.pickup, 'Where should we pick you up?'),
      RoutePoint.stop => (SangaStopKind.stop, 'Where should we stop?'),
      RoutePoint.dropoff => (SangaStopKind.dropoff, 'Where are you going?'),
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
        body: Stack(
          children: [
            Positioned.fill(
              child: SangaMap(camera: _camera, followsUser: false, extraMarkers: _markers, extraPolylines: _polylines),
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
            Align(
              alignment: Alignment.bottomCenter,
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
                  return false;
                },
                child: SizeChangedLayoutNotifier(
                  child: RoutePanel(
                    key: _panelKey,
                    pickup: _ride.pickup,
                    stops: _ride.stops,
                    dropoff: _ride.dropoff,
                    canAddStop: _ride.canAddStop,
                    onEdit: _edit,
                    onRemoveStop: _removeStop,
                    onConfirm: _ride.hasRoute ? () => context.push(SangaRoutes.tripType) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
