import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/services/directions_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/map/car_marker.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/map/sanga_map.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<LatLng> tripFramePoints(Trip trip) {
  final driver = trip.driverPosition?.position;
  if (trip.delivery?.stage == DeliveryStage.returning) return [?driver, trip.pickup.position];
  if (trip.status.rank >= TripStatus.inProgress.rank) {
    return [
      ?driver,
      for (final stop in trip.stops)
        if (!stop.isReached) stop.position,
      trip.dropoff.position,
    ];
  }
  if (!trip.status.isTerminal) return [?driver, trip.pickup.position];
  return [for (final place in trip.route) place.position];
}

class TripMap extends StatefulWidget {
  const TripMap({super.key, required this.trip, required this.camera, this.onMapCreated});

  final Trip? trip;
  final MapCamera camera;
  final VoidCallback? onMapCreated;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  static const String _routeId = 'route';
  static const int _dashesPerRoute = 40;

  final _directions = DirectionsService();
  Set<Marker> _placeMarkers = const {};
  Set<Marker> _carMarkers = const {};
  Set<Polyline> _polylines = const {};
  int _routeRequest = 0;
  int _carRequest = 0;

  List<LatLng> get _routePoints => [for (final place in widget.trip?.route ?? const <TripPlace>[]) place.position];

  @override
  void initState() {
    super.initState();
    _drawRoute();
    _drawCar();
  }

  @override
  void didUpdateWidget(TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trip = widget.trip;
    final before = oldWidget.trip;
    if (!_sameRoute(trip, before)) _drawRoute();
    if (trip?.driverPosition?.position != before?.driverPosition?.position ||
        trip?.driverPosition?.heading != before?.driverPosition?.heading) {
      _drawCar();
    }
  }

  bool _sameRoute(Trip? a, Trip? b) {
    final left = a?.route ?? const <TripPlace>[];
    final right = b?.route ?? const <TripPlace>[];
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].position != right[i].position) return false;
    }
    return true;
  }

  Future<void> _drawCar() async {
    final request = ++_carRequest;
    final driver = widget.trip?.driverPosition;
    final markers = driver == null
        ? const <Marker>{}
        : {await CarMarker.marker(position: driver.position, heading: driver.heading)};
    if (!mounted || request != _carRequest) return;
    setState(() => _carMarkers = markers);
  }

  Future<void> _drawRoute() async {
    final request = ++_routeRequest;
    final markers = await _buildMarkers();
    if (!mounted || request != _routeRequest) return;
    setState(() {
      _placeMarkers = markers;
      _polylines = _straightLine();
    });
    final route = await _directions.getRoute(_routePoints);
    if (!mounted || request != _routeRequest || route == null) return;
    setState(() => _polylines = {_polyline(route)});
  }

  Future<Set<Marker>> _buildMarkers() async {
    final trip = widget.trip;
    if (trip == null) return const {};
    return {
      await PlaceMarker.marker(
        id: 'pickup',
        kind: PlaceMarkerKind.pickup,
        position: trip.pickup.position,
        title: trip.pickup.name,
        subtitle: 'Pick up point',
      ),
      for (final (index, stop) in trip.stops.indexed)
        await PlaceMarker.marker(
          id: 'stop_$index',
          kind: PlaceMarkerKind.stop,
          position: stop.position,
          title: stop.name,
          subtitle: 'Stop ${index + 1}',
        ),
      await PlaceMarker.marker(
        id: 'dropoff',
        kind: PlaceMarkerKind.dropoff,
        position: trip.dropoff.position,
        title: trip.dropoff.name,
        subtitle: 'Drop off point',
      ),
    };
  }

  Set<Polyline> _straightLine() {
    final points = _routePoints;
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

  @override
  Widget build(BuildContext context) {
    return SangaMap(
      camera: widget.camera,
      followsUser: false,
      onMapCreated: widget.onMapCreated,
      extraMarkers: {..._placeMarkers, ..._carMarkers},
      extraPolylines: _polylines,
    );
  }
}
