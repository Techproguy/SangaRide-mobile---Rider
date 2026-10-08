import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PackagePhotoCircle extends StatelessWidget {
  const PackagePhotoCircle({super.key, required this.state, required this.onTap, this.size = 240});

  static const double _decodeWidth = 720;

  final PackagePhotoState state;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = state.localPath;
    final hasPhoto = path != null;
    return Semantics(
      button: true,
      label: hasPhoto ? 'Package photo' : 'Add a package photo',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          foregroundPainter: hasPhoto ? null : const _DashedCirclePainter(),
          child: ClipOval(
            child: Material(
              color: hasPhoto ? SangaColors.textPrimary : SangaColors.primaryWash,
              child: InkWell(
                onTap: state.isBusy ? null : onTap,
                child: SangaHandoff(value: state.runtimeType, child: _content(path)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(String? path) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (path != null)
            Image(
              image: ResizeImage(FileImage(File(path)), width: _decodeWidth.toInt()),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(color: SangaColors.fill),
            ),
          ..._overlay(),
        ],
      ),
    );
  }

  List<Widget> _overlay() => switch (state) {
    PhotoNone() => const [_Caption(icon: SangaIcon(SangaAssets.camera, size: 28), text: 'Tap to add a photo')],
    PhotoPreparing() => const [_Caption(icon: _Spinner(), text: 'Getting your photo ready')],
    PhotoUploading(:final progress) => [
      const ColoredBox(color: SangaColors.scrim),
      _Caption(
        icon: _Spinner(value: progress, isLight: true),
        text: '${(progress * 100).round()}%',
        isLight: true,
      ),
    ],
    PhotoUploaded() => const [Align(alignment: Alignment(0, 0.82), child: SangaIcon(SangaAssets.checkBadge, size: 32))],
    PhotoFailed() => [
      const ColoredBox(color: SangaColors.scrim),
      const Center(child: Icon(Icons.error_outline_rounded, color: SangaColors.onPrimary, size: 40)),
    ],
  };
}

class _Caption extends StatelessWidget {
  const _Caption({required this.icon, required this.text, this.isLight = false});

  final Widget icon;
  final String text;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          icon,
          Text(
            text,
            textAlign: TextAlign.center,
            style: SangaTextStyles.label.copyWith(color: isLight ? SangaColors.onPrimary : SangaColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.value, this.isLight = false});

  final double? value;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 3,
        color: isLight ? SangaColors.onPrimary : SangaColors.primary,
        backgroundColor: isLight ? SangaColors.onPrimary.withValues(alpha: 0.3) : null,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()..addOval((Offset.zero & size).deflate(0.5));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = SangaColors.primary;
    for (final metric in outline.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += _dash + _gap) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}
