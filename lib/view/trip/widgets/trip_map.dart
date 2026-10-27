import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final MapCameraDirector camera;
  final VoidCallback? onMapCreated;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  final _tripLine = SangaRouteLines(id: 'trip');
  final _approachLine = SangaRouteLines(id: 'approach', style: SangaRouteStyle.approach);
  late final CarGlide _glide = CarGlide(onFrame: _showCar);
  Set<Marker> _placeMarkers = const {};
  Set<Marker> _carMarkers = const {};
  int _routeRequest = 0;
  String? _approachKey;

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
    final labelMoved = trip != null && before != null && _nextLabelled(trip) != _nextLabelled(before);
    if (!_sameRoute(trip, before) || labelMoved) _drawRoute();
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
      _glide.clear();
      setState(() => _carMarkers = const {});
      return;
    }
    _glide.moveTo(driver.position, driver.heading ?? _glide.heading);
  }

  void _showCar(LatLng position, double heading) {
    if (!mounted) return;
    setState(() => _carMarkers = {CarMarker.build(position: position, heading: heading)});
    _syncLines();
  }

  void _syncLines() {
    final car = _glide.position;
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
    final next = _nextLabelled(trip);
    return {
      await PlaceMarker.marker(
        id: 'pickup',
        kind: PlaceMarkerKind.pickup,
        position: trip.pickup.position,
        title: trip.pickup.title,
        subtitle: 'Pick up point',
        showsLabel: next == _pickupLabel,
      ),
      for (final (index, stop) in trip.stops.indexed)
        await PlaceMarker.marker(
          id: 'stop_$index',
          kind: PlaceMarkerKind.stop,
          position: stop.position,
          title: stop.title,
          subtitle: 'Stop ${index + 1}',
          showsLabel: next == index,
        ),
      await PlaceMarker.marker(
        id: 'dropoff',
        kind: PlaceMarkerKind.dropoff,
        position: trip.dropoff.position,
        title: trip.dropoff.title,
        subtitle: 'Drop off point',
        showsLabel: next == _dropoffLabel,
      ),
    };
  }

  static const int _pickupLabel = -1;
  static const int _dropoffLabel = -2;

  int _nextLabelled(Trip trip) {
    if (trip.status.isTerminal) return _dropoffLabel;
    if (trip.status.rank < TripStatus.inProgress.rank) return _pickupLabel;
    final nextStop = trip.stops.indexWhere((stop) => !stop.isReached);
    return nextStop < 0 ? _dropoffLabel : nextStop;
  }

  void _onCameraMove(CameraPosition position) {
    _tripLine.updateZoom(position.zoom);
    _approachLine.updateZoom(position.zoom);
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
        onCameraMove: _onCameraMove,
      ),
    );
  }
}
