import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/shared/map_camera.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/core/constants.dart';

class SangaMap extends StatefulWidget {
  final CameraPosition? initialCameraPosition;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final MapType mapType;
  final ValueChanged<LatLng>? onMapTap;
  final ValueChanged<LatLng>? onMapLongPress;
  final VoidCallback? onMapCreated;
  final VoidCallback? onCameraIdle;
  final ValueChanged<CameraPosition>? onCameraMove;
  final Set<Marker>? extraMarkers;
  final Set<Polyline>? extraPolylines;
  final String? style;
  final MapCamera? camera;
  final bool followsUser;

  const SangaMap({
    super.key,
    this.initialCameraPosition,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapType = MapType.normal,
    this.onMapTap,
    this.onMapLongPress,
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
  Worker? _locationWatcher;
  bool _centeredOnUser = false;

  MapCamera get _camera => widget.camera ?? _mapController.camera;

  CameraPosition get _initialPosition {
    if (widget.initialCameraPosition != null) return widget.initialCameraPosition!;
    final current = _mapController.currentLocation;
    if (current != null) return CameraPosition(target: current, zoom: _userZoom);
    return const CameraPosition(target: SangaConstants.defaultMapCenter, zoom: 12.0);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.followsUser) return;
    final current = _mapController.currentLocation;
    if (current != null) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _camera.moveTo(current, zoom: _userZoom);
      });
    }
    _locationWatcher = ever(_mapController.currentLocationObs, (LatLng? loc) {
      if (loc == null || _centeredOnUser || !mounted) return;
      _centeredOnUser = true;
      _camera.moveTo(loc, zoom: _userZoom);
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
        _camera.mapSize = constraints.biggest;
        return Obx(
          () => GoogleMap(
            mapType: widget.mapType,
            style: widget.style,
            initialCameraPosition: _initialPosition,
            markers: {..._mapController.markers, ...?widget.extraMarkers},
            polylines: {..._mapController.polylines, ...?widget.extraPolylines},
            onMapCreated: (controller) {
              _gmController = controller;
              _camera.attach(controller);
              widget.onMapCreated?.call();
            },
            onTap: widget.onMapTap,
            onLongPress: widget.onMapLongPress,
            onCameraIdle: widget.onCameraIdle,
            onCameraMove: widget.onCameraMove,
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
