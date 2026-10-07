import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

class MockCapture {
  MockCapture._();

  static const Size _size = Size(720, 960);

  static Future<String> photo(String label) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Offset.zero & _size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, const [Color(0xFF1C74FE), Color(0xFF0B2E66)]),
    );
    final text = TextPainter(
      text: TextSpan(
        text: 'Mock photo\n$label',
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 56, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _size.width);
    text.paint(canvas, Offset((_size.width - text.width) / 2, (_size.height - text.height) / 2));
    final image = await recorder.endRecording().toImage(_size.width.toInt(), _size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${Directory.systemTemp.path}/mock_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file.path;
  }
}
