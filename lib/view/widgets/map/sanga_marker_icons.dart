import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SangaMarkerIcons {
  SangaMarkerIcons._();

  static const double _kPixelRatio = 3.0;
  static const double _kSelfSize = 44.0;
  static const double _kPinWidth = 44.0;
  static const double _kPinHeight = 60.0;

  static const double _kShadowBlur = 3.0;
  static const double _kShadowAlpha = 0.18;
  static const Offset _kShadowOffset = Offset(0, 2.5);

  static const Color _kDropoffColor = Color(0xFF2C2F33);
  static const Color _kPickupColor = Color(0xFF228B22);

  static BitmapDescriptor? _self;
  static BitmapDescriptor? _pickup;
  static BitmapDescriptor? _dropoff;
  static BitmapDescriptor? _driver;

  static Future<void> preload() async {
    await Future.wait<void>([self(), pickup(), dropoff(), driver()]);
  }

  static Future<BitmapDescriptor> self() async => _self ??= await _paintSelf();

  static Future<BitmapDescriptor> pickup() async =>
      _pickup ??= await _paintPin(innerColor: _kPickupColor, glyph: Icons.person_rounded);

  static Future<BitmapDescriptor> dropoff() async =>
      _dropoff ??= await _paintPin(innerColor: _kDropoffColor, glyph: Icons.flag_rounded);

  static Future<BitmapDescriptor> driver() async =>
      _driver ??= await _paintPin(innerColor: SangaColors.primary, glyph: Icons.directions_car_filled_rounded);

  static Future<BitmapDescriptor> _paintSelf() async {
    final canvasSize = _kSelfSize * _kPixelRatio;
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final outerRadius = canvasSize / 2 - 4 * _kPixelRatio;
    final ringRadius = outerRadius - 2 * _kPixelRatio;
    final coreRadius = ringRadius - 2.5 * _kPixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    _drawShadow(canvas, center, outerRadius, paint);
    paint
      ..maskFilter = null
      ..color = SangaColors.primary;
    canvas.drawCircle(center, outerRadius, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, ringRadius, paint);
    paint.color = SangaColors.primary;
    canvas.drawCircle(center, coreRadius, paint);

    return _record(recorder, canvasSize.toInt());
  }

  static Future<BitmapDescriptor> _paintPin({required Color innerColor, required IconData glyph}) async {
    const canvasW = _kPinWidth * _kPixelRatio;
    const canvasH = _kPinHeight * _kPixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    const bodyRadius = canvasW / 2 - 2 * _kPixelRatio;
    const bodyCenter = Offset(canvasW / 2, bodyRadius + 2 * _kPixelRatio);

    _drawShadow(canvas, bodyCenter + const Offset(0, 1.5), bodyRadius, paint);

    paint
      ..maskFilter = null
      ..color = SangaColors.primary;
    final tail = Path()
      ..moveTo(bodyCenter.dx - bodyRadius * 0.55, bodyCenter.dy + bodyRadius * 0.4)
      ..lineTo(bodyCenter.dx + bodyRadius * 0.55, bodyCenter.dy + bodyRadius * 0.4)
      ..lineTo(bodyCenter.dx, canvasH - 2 * _kPixelRatio)
      ..close();
    canvas.drawPath(tail, paint);

    canvas.drawCircle(bodyCenter, bodyRadius, paint);
    paint.color = Colors.white;
    canvas.drawCircle(bodyCenter, bodyRadius - 3 * _kPixelRatio, paint);
    paint.color = innerColor;
    canvas.drawCircle(bodyCenter, bodyRadius - 5 * _kPixelRatio, paint);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: bodyRadius,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, bodyCenter - Offset(iconPainter.width / 2, iconPainter.height / 2));

    return _record(recorder, canvasW.toInt(), height: canvasH.toInt());
  }

  static void _drawShadow(Canvas canvas, Offset center, double radius, Paint paint) {
    paint
      ..color = Colors.black.withValues(alpha: _kShadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _kShadowBlur);
    canvas.drawCircle(center + _kShadowOffset, radius, paint);
  }

  static Future<BitmapDescriptor> _record(ui.PictureRecorder recorder, int width, {int? height}) async {
    final image = await recorder.endRecording().toImage(width, height ?? width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: _kPixelRatio);
  }
}
