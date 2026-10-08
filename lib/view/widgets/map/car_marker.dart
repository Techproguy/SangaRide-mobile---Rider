import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class CarMarker {
  static const double _scale = 3;
  static const double _width = 28;
  static const double _height = 46;
  static const double _bodyRadius = 8;

  static BitmapDescriptor? _icon;

  static Future<Marker> marker({required LatLng position, double? heading}) async {
    final icon = _icon ??= await _paint();
    return Marker(
      markerId: const MarkerId('driver'),
      position: position,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: heading ?? 0,
      zIndexInt: 3,
    );
  }

  static Future<BitmapDescriptor> _paint() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 20, 38), const Radius.circular(_bodyRadius));
    canvas
      ..drawRRect(
        body.shift(const Offset(0, 1.5)),
        Paint()
          ..color = SangaColors.sheetShadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      )
      ..drawRRect(body.inflate(1.5), Paint()..color = SangaColors.surface)
      ..drawRRect(body, Paint()..color = SangaColors.primary);
    final glass = Paint()..color = SangaColors.textPrimary.withValues(alpha: 0.78);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 11, 14, 9), const Radius.circular(3)), glass)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 30, 14, 6), const Radius.circular(2.5)), glass);
    final lights = Paint()..color = SangaColors.star;
    canvas
      ..drawCircle(const Offset(8.5, 6.5), 1.7, lights)
      ..drawCircle(const Offset(19.5, 6.5), 1.7, lights);
    final image = await recorder.endRecording().toImage((_width * _scale).ceil(), (_height * _scale).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: _scale);
  }
}
