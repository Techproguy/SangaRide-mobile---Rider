import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
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
  const TripMap({super.key, required this.trip, required this.camera, this.onMapCreated, this.onUserPan});

  final Trip? trip;
  final MapCamera camera;
  final VoidCallback? onMapCreated;
  final VoidCallback? onUserPan;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> with SingleTickerProviderStateMixin {
  static const String _routeId = 'route';
  static const int _dashesPerRoute = 40;
  static const Duration _glideDuration = TripController.pollInterval;
  static const Duration _frameGap = Duration(milliseconds: 60);
  static const double _panSlop = 10;

  final _directions = DirectionsService();
  late final AnimationController _glide = AnimationController(vsync: this, duration: _glideDuration)
    ..addListener(_onGlide);
  Set<Marker> _placeMarkers = const {};
  Set<Marker> _carMarkers = const {};
  Set<Polyline> _polylines = const {};
  List<LatLng> _route = const [];
  bool _isRouteDetailed = false;
  int _routeRequest = 0;
  int _routeCursor = 0;
  LatLng? _carFrom;
  LatLng? _carTo;
  double _headingFrom = 0;
  double _headingTo = 0;
  LatLng? _carNow;
  double _headingNow = 0;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  double _panned = 0;

  List<LatLng> get _routePoints => [for (final place in widget.trip?.route ?? const <TripPlace>[]) place.position];

  bool get _trimsRoute => (widget.trip?.status.rank ?? 0) >= TripStatus.inProgress.rank;

  @override
  void initState() {
    super.initState();
    _drawRoute();
    unawaited(CarMarker.ensureIcon().then((_) => _driveTo(widget.trip?.driverPosition)));
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trip = widget.trip;
    final before = oldWidget.trip;
    if (!_sameRoute(trip, before)) _drawRoute();
    if (trip?.driverPosition?.position != before?.driverPosition?.position ||
        trip?.driverPosition?.heading != before?.driverPosition?.heading) {
      _driveTo(trip?.driverPosition);
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

  void _driveTo(DriverPosition? driver) {
    if (!mounted) return;
    if (driver == null) {
      _glide.stop();
      _carNow = null;
      _carFrom = null;
      _carTo = null;
      setState(() => _carMarkers = const {});
      return;
    }
    final heading = driver.heading ?? _headingNow;
    final here = _carNow;
    if (here == null) {
      _carFrom = _carTo = driver.position;
      _headingFrom = _headingTo = heading;
      _showCar(driver.position, heading);
      return;
    }
    _carFrom = here;
    _carTo = driver.position;
    _headingFrom = _headingNow;
    _headingTo = heading;
    _glide.forward(from: 0);
  }

  void _onGlide() {
    final from = _carFrom;
    final to = _carTo;
    if (from == null || to == null) return;
    final now = DateTime.now();
    final isLast = _glide.value >= 1;
    if (!isLast && now.difference(_lastFrame) < _frameGap) return;
    _lastFrame = now;
    final t = _glide.value;
    final position = LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
    final heading = _easedHeading(_headingFrom, _headingTo, Curves.easeInOut.transform(t));
    _showCar(position, heading);
  }

  double _easedHeading(double from, double to, double t) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    return (from + delta * t) % 360;
  }

  void _showCar(LatLng position, double heading) {
    if (!mounted) return;
    _carNow = position;
    _headingNow = heading;
    setState(() {
      _carMarkers = {CarMarker.build(position: position, heading: heading)};
      if (_trimsRoute) _polylines = _trimmed(position);
    });
  }

  Set<Polyline> _trimmed(LatLng car) {
    final route = _route;
    if (route.length < 2) return _polylines;
    var best = _routeCursor.clamp(0, route.length - 1);
    var bestDistance = car.metersTo(route[best]);
    for (var i = best + 1; i < route.length && i <= best + 40; i++) {
      final distance = car.metersTo(route[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    _routeCursor = best;
    final remaining = [car, ...route.skip(best + 1)];
    if (remaining.length < 2) return const {};
    return {_isRouteDetailed ? _polyline(remaining) : _dashedLine(remaining)};
  }

  Future<void> _drawRoute() async {
    final request = ++_routeRequest;
    final markers = await _buildMarkers();
    if (!mounted || request != _routeRequest) return;
    _route = _routePoints;
    _isRouteDetailed = false;
    _routeCursor = 0;
    setState(() {
      _placeMarkers = markers;
      _polylines = _straightLine();
    });
    final route = await _directions.getRoute(_routePoints);
    if (!mounted || request != _routeRequest || route == null) return;
    _route = route;
    _isRouteDetailed = true;
    _routeCursor = 0;
    setState(() => _polylines = _trimsRoute && _carNow != null ? _trimmed(_carNow!) : {_polyline(route)});
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
    return {_dashedLine(points)};
  }

  Polyline _dashedLine(List<LatLng> points) {
    return Polyline(
      polylineId: const PolylineId(_routeId),
      points: points,
      color: SangaColors.primary,
      width: 4,
      patterns: _dashes(points),
    );
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

  void _onPointerMove(PointerMoveEvent event) {
    _panned += event.delta.distance;
    if (_panned > _panSlop) {
      _panned = 0;
      widget.onUserPan?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _panned = 0,
      onPointerMove: _onPointerMove,
      child: SangaMap(
        camera: widget.camera,
        followsUser: false,
        onMapCreated: widget.onMapCreated,
        extraMarkers: {..._placeMarkers, ..._carMarkers},
        extraPolylines: _polylines,
      ),
    );
  }
}
