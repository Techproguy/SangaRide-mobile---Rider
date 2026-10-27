import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart';

class SangaMap extends StatefulWidget {
  final CameraPosition? initialCameraPosition;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final MapType mapType;
  final VoidCallback? onMapCreated;
  final VoidCallback? onCameraIdle;
  final ValueChanged<CameraPosition>? onCameraMove;
  final Set<Marker>? extraMarkers;
  final Set<Polyline>? extraPolylines;
  final String? style;
  final MapCameraDirector? camera;
  final bool followsUser;

  const SangaMap({
    super.key,
    this.initialCameraPosition,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onCameraIdle,
    this.onCameraMove,
    this.extraMarkers,
    this.extraPolylines,
    this.style,
    this.camera,
    this.followsUser = true,
  });

  @override
  State<SangaMap> createState() => _SangaMapState();
}

class _SangaMapState extends State<SangaMap> {
  static const double _userZoom = 15.0;

  final MapController _mapController = Get.find<MapController>();
  GoogleMapController? _gmController;
  Size _size = Size.zero;
  Worker? _locationWatcher;
  bool _centeredOnUser = false;

  MapCameraDirector get _camera => widget.camera ?? _mapController.camera;

  CameraPosition get _initialPosition {
    if (widget.initialCameraPosition != null) return widget.initialCameraPosition!;
    final current = _mapController.currentLocation;
    if (current != null) return CameraPosition(target: current, zoom: _userZoom);
    return CameraPosition(target: SangaConstants.defaultMapCenter, zoom: 12.0);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.followsUser) return;
    final current = _mapController.currentLocation;
    if (current != null) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_camera.moveTo(current, zoom: _userZoom));
      });
    }
    _locationWatcher = ever(_mapController.currentLocationObs, (LatLng? loc) {
      if (loc == null || _centeredOnUser || !mounted) return;
      _centeredOnUser = true;
      unawaited(_camera.moveTo(loc, zoom: _userZoom));
    });
  }

  @override
  void dispose() {
    _locationWatcher?.dispose();
    _camera.detach(_gmController);
    _gmController?.dispose();
    _gmController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        _camera.resize(_gmController, _size);
        final initial = _initialPosition;
        return Listener(
          onPointerMove: (_) => _camera.takeOver(),
          child: GoogleMap(
            mapType: widget.mapType,
            style: widget.style,
            initialCameraPosition: initial,
            markers: {...?widget.extraMarkers},
            polylines: {...?widget.extraPolylines},
            onMapCreated: (controller) {
              _gmController = controller;
              _camera.attach(controller, _size, initial);
              widget.onMapCreated?.call();
            },
            onCameraIdle: widget.onCameraIdle,
            onCameraMove: (position) {
              _camera.onCameraMove(_gmController, position);
              widget.onCameraMove?.call(position);
            },
            myLocationButtonEnabled: widget.myLocationButtonEnabled,
            zoomControlsEnabled: widget.zoomControlsEnabled,
            myLocationEnabled: widget.myLocationEnabled,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(PanGestureRecognizer.new),
              Factory<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new),
              Factory<VerticalDragGestureRecognizer>(VerticalDragGestureRecognizer.new),
            },
          ),
        );
      },
    );
  }
}
