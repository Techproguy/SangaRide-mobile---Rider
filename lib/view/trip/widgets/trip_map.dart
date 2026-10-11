import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/map/car_marker.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/map/sanga_map.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart';

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

class _TripMapState extends State<TripMap> with SingleTickerProviderStateMixin {
  static const Duration _glideDuration = TripController.pollInterval;
  static const Duration _frameGap = Duration(milliseconds: 60);

  final _tripLine = SangaRouteLines(id: 'trip');
  final _approachLine = SangaRouteLines(id: 'approach', style: SangaRouteStyle.approach);
  late final AnimationController _glide = AnimationController(vsync: this, duration: _glideDuration)
    ..addListener(_onGlide);
  Set<Marker> _placeMarkers = const {};
  Set<Marker> _carMarkers = const {};
  int _routeRequest = 0;
  String? _approachKey;
  LatLng? _carFrom;
  LatLng? _carTo;
  double _headingFrom = 0;
  double _headingTo = 0;
  LatLng? _carNow;
  double _headingNow = 0;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  List<LatLng> get _routePoints => [for (final place in widget.trip?.route ?? const <TripPlace>[]) place.position];

  bool get _trimsRoute => (widget.trip?.status.rank ?? 0) >= TripStatus.inProgress.rank;

  bool get _isApproaching => widget.trip?.status == TripStatus.driverEnRoute;

  @override
  void initState() {
    super.initState();
    _drawRoute();
    unawaited(CarMarker.ensureIcon().then((_) => _driveTo(widget.trip?.driverPosition)));
  }

  @override
  void dispose() {
    _glide.dispose();
    _tripLine.dispose();
    _approachLine.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trip = widget.trip;
    final before = oldWidget.trip;
    if (!_sameRoute(trip, before)) _drawRoute();
    if (trip?.status != before?.status) _syncLines();
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
    setState(() => _carMarkers = {CarMarker.build(position: position, heading: heading)});
    _syncLines();
  }

  void _syncLines() {
    final car = _carNow;
    _tripLine.follow(_trimsRoute ? car : null);
    final pickup = widget.trip?.pickup.position;
    if (!_isApproaching || car == null || pickup == null) {
      _approachKey = null;
      _approachLine.clear();
      return;
    }
    final key = '${pickup.latitude},${pickup.longitude}';
    if (key != _approachKey) {
      _approachKey = key;
      _approachLine.show([car, pickup]);
    }
    _approachLine.follow(car);
  }

  Future<void> _drawRoute() async {
    final request = ++_routeRequest;
    final markers = await _buildMarkers();
    if (!mounted || request != _routeRequest) return;
    setState(() => _placeMarkers = markers);
    _tripLine.show(_routePoints);
    _syncLines();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_tripLine, _approachLine]),
      builder: (context, _) => SangaMap(
        camera: widget.camera,
        followsUser: false,
        onMapCreated: widget.onMapCreated,
        extraMarkers: {..._placeMarkers, ..._carMarkers},
        extraPolylines: {..._tripLine.polylines, ..._approachLine.polylines},
      ),
    );
  }
}
