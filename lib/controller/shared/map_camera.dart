import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';

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
    if (controller == null || points.isEmpty) return;
    if (points.every((point) => point.metersTo(points.first) < _samePlaceMeters)) {
      return moveTo(points.first, zoom: singlePointZoom);
    }
    try {
      var minLat = points.first.latitude, maxLat = minLat;
      var minLng = points.first.longitude, maxLng = minLng;
      for (final p in points.skip(1)) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final ins = visibleInsets;
      final visH = mapSize.height - ins.top - ins.bottom - padding * 2;
      final visW = mapSize.width - ins.left - ins.right - padding * 2;
      if (visH > 0) {
        final latSpan = (maxLat - minLat).abs();
        maxLat += latSpan * (ins.top / visH);
        minLat -= latSpan * (ins.bottom / visH);
      }
      if (visW > 0) {
        final lngSpan = (maxLng - minLng).abs();
        minLng -= lngSpan * (ins.left / visW);
        maxLng += lngSpan * (ins.right / visW);
      }

      final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
      if (await controller.getZoomLevel() > maxZoom) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2), maxZoom),
        );
      }
    } on StateError {
      return;
    }
  }
}
