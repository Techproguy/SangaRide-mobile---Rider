import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum PlaceMarkerKind { current, pickup, stop, dropoff }

class PlaceMarkerIcon {
  const PlaceMarkerIcon(this.icon, this.anchor);

  final BitmapDescriptor icon;
  final Offset anchor;
}

abstract final class PlaceMarker {
  static const double _scale = 3;
  static const double _bubbleRadius = 7;
  static const double _pointer = 5;
  static const double _gap = 2;
  static const double _pinSize = 34;
  static const double _dotRadius = 8;
  static const double _haloRadius = 18;

  static final Map<String, PlaceMarkerIcon> _cache = {};

  static Future<Marker> marker({
    required String id,
    required PlaceMarkerKind kind,
    required LatLng position,
    required String title,
    String? subtitle,
  }) async {
    final icon = await _icon(kind, title, subtitle);
    return Marker(markerId: MarkerId(id), position: position, icon: icon.icon, anchor: icon.anchor, zIndexInt: 2);
  }

  static Future<PlaceMarkerIcon> _icon(PlaceMarkerKind kind, String title, String? subtitle) async {
    final key = '${kind.name}|$title|$subtitle';
    return _cache[key] ??= await _paint(kind, title, subtitle);
  }

  static Future<PlaceMarkerIcon> _paint(PlaceMarkerKind kind, String title, String? subtitle) async {
    final titlePainter = _text(title, SangaTextStyles.mapLabel);
    final subtitlePainter = subtitle == null
        ? null
        : _text(subtitle, SangaTextStyles.mapLabel.copyWith(fontSize: 7.5, color: SangaColors.textFaint));
    const padH = 8.0;
    const padV = 5.0;
    final textWidth = [titlePainter.width, subtitlePainter?.width ?? 0].reduce((a, b) => a > b ? a : b);
    final bubbleWidth = textWidth + padH * 2;
    final bubbleHeight = titlePainter.height + (subtitlePainter?.height ?? 0) + padV * 2;
    final pinHeight = kind == PlaceMarkerKind.current ? _haloRadius * 2 : _pinSize;
    final width = [bubbleWidth, _haloRadius * 2, _pinSize].reduce((a, b) => a > b ? a : b) + 6;
    final height = bubbleHeight + _pointer + _gap + pinHeight + 4;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    final centerX = width / 2;
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - bubbleWidth / 2, 2, bubbleWidth, bubbleHeight),
      const Radius.circular(_bubbleRadius),
    );
    canvas.drawRRect(
      bubble.shift(const Offset(0, 1.5)),
      Paint()
        ..color = SangaColors.cardShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final white = Paint()..color = SangaColors.surface;
    canvas
      ..drawRRect(bubble, white)
      ..drawPath(
        Path()
          ..moveTo(centerX - _pointer, bubble.bottom - 0.5)
          ..lineTo(centerX + _pointer, bubble.bottom - 0.5)
          ..lineTo(centerX, bubble.bottom + _pointer)
          ..close(),
        white,
      );
    titlePainter.paint(canvas, Offset(centerX - bubbleWidth / 2 + padH, bubble.top + padV));
    subtitlePainter?.paint(canvas, Offset(centerX - bubbleWidth / 2 + padH, bubble.top + padV + titlePainter.height));

    final pinTop = bubble.bottom + _pointer + _gap;
    double anchorY;
    if (kind == PlaceMarkerKind.current) {
      final center = Offset(centerX, pinTop + _haloRadius);
      canvas
        ..drawCircle(center, _haloRadius, Paint()..color = SangaColors.success.withValues(alpha: 0.18))
        ..drawCircle(center, _dotRadius + 2.5, white)
        ..drawCircle(center, _dotRadius, Paint()..color = SangaColors.success);
      anchorY = center.dy;
    } else {
      final glyph = _glyph(kind);
      glyph.paint(canvas, Offset(centerX - glyph.width / 2, pinTop));
      anchorY = pinTop + _pinSize * 0.9;
    }

    final image = await recorder.endRecording().toImage((width * _scale).ceil(), (height * _scale).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = bytes == null
        ? BitmapDescriptor.defaultMarker
        : BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: _scale);
    return PlaceMarkerIcon(icon, Offset(0.5, anchorY / height));
  }

  static TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 160);

  static TextPainter _glyph(PlaceMarkerKind kind) {
    const icon = Icons.location_on_rounded;
    final color = switch (kind) {
      PlaceMarkerKind.pickup => SangaColors.pinPickup,
      PlaceMarkerKind.stop => SangaColors.primary,
      _ => SangaColors.pinDropoff,
    };
    return TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: _pinSize, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
