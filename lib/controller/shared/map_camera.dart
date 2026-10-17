import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart';

class MapCamera {
  static const double _samePlaceMeters = 200;

  GoogleMapController? _controller;
  EdgeInsets visibleInsets = EdgeInsets.zero;
  Size mapSize = Size.zero;

  void attach(GoogleMapController controller) => _controller = controller;

  void detach(GoogleMapController? controller) {
    if (controller == null || identical(controller, _controller)) _controller = null;
  }

  LatLng _biasToVisible(LatLng target, LatLngBounds region, double scale) {
    final h = mapSize.height, w = mapSize.width;
    if (h <= 0 || w <= 0) return target;
    final latSpan = (region.northeast.latitude - region.southwest.latitude) * scale;
    final lngSpan = (region.northeast.longitude - region.southwest.longitude) * scale;
    final latShift = ((visibleInsets.top - visibleInsets.bottom) / (2 * h)) * latSpan;
    final lngShift = ((visibleInsets.right - visibleInsets.left) / (2 * w)) * lngSpan;
    return LatLng(target.latitude + latShift, target.longitude + lngShift);
  }

  Future<void> moveTo(LatLng position, {double zoom = 14.0}) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final region = await controller.getVisibleRegion();
      final scale = math.pow(2, await controller.getZoomLevel() - zoom).toDouble();
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: _biasToVisible(position, region, scale), zoom: zoom)),
      );
    } on StateError {
      return;
    }
  }

  Future<void> fitBounds(
    List<LatLng> points, {
    double padding = 60,
    double singlePointZoom = 15,
    double maxZoom = 16.5,
  }) async {
    final controller = _controller;
    if (controller == null || points.isEmpty || mapSize.isEmpty) return;
    final position = CameraFit.of(
      points,
      mapSize: mapSize,
      insets: visibleInsets,
      padding: padding,
      maxZoom: maxZoom,
      singlePointZoom: singlePointZoom,
      samePlaceMeters: _samePlaceMeters,
    );
    try {
      await controller.animateCamera(CameraUpdate.newCameraPosition(position));
    } on StateError {
      return;
    }
  }
}
