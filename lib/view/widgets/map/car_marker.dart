import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract final class CarMarker {
  static const Size _size = Size(28, 60);
  static const String _asset = 'assets/images/map_car.webp';
  static const String _uiPackage = 'sanga_ride_ui';

  static BitmapDescriptor? _icon;

  static bool get isReady => _icon != null;

  static Future<Marker> marker({required LatLng position, double? heading}) async {
    await ensureIcon();
    return build(position: position, heading: heading);
  }

  static Future<void> ensureIcon() async {
    _icon ??= await _paint();
  }

  static Marker build({required LatLng position, double? heading}) {
    return Marker(
      markerId: const MarkerId('driver'),
      position: position,
      icon: _icon ?? BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: heading ?? 0,
      zIndexInt: 3,
    );
  }

  static Future<BitmapDescriptor> _paint() => BitmapDescriptor.asset(
    const ImageConfiguration(size: _size),
    _asset,
    package: _uiPackage,
    width: _size.width,
    height: _size.height,
  );
}
