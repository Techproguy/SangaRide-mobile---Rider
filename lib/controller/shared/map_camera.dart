import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';

class MapCamera {
  static const double _samePlaceMeters = 200;
  static const double _tileSize = 256;

  static double _log2(double value) => math.log(value) / math.ln2;

  static double _mercatorY(double latitude) => math.log(math.tan(math.pi / 4 + latitude * math.pi / 360));

  static double _latitudeOf(double mercatorY) => (2 * math.atan(math.exp(mercatorY)) - math.pi / 2) * 180 / math.pi;

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
      final visW = mapSize.width - ins.left - ins.right - padding * 2;
      final visH = mapSize.height - ins.top - ins.bottom - padding * 2;
      if (visW <= 0 || visH <= 0) {
        final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
        return await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
      }
      final yTop = _mercatorY(maxLat), yBottom = _mercatorY(minLat);
      final zoomForWidth = _log2(visW * 360 / (math.max(maxLng - minLng, 1e-9) * _tileSize));
      final zoomForHeight = _log2(visH * 2 * math.pi / (math.max(yTop - yBottom, 1e-9) * _tileSize));
      final zoom = math.min(maxZoom, math.min(zoomForWidth, zoomForHeight));
      final worldPx = _tileSize * math.pow(2, zoom);
      final shiftX = (ins.right - ins.left) / 2;
      final shiftY = (ins.bottom - ins.top) / 2;
      final centerLng = (minLng + maxLng) / 2 + shiftX * 360 / worldPx;
      final centerY = (yTop + yBottom) / 2 - shiftY * 2 * math.pi / worldPx;
      final target = LatLng(_latitudeOf(centerY), centerLng);
      await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: zoom)));
    } on StateError {
      return;
    }
  }
}
