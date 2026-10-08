import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CompletedHeader extends StatelessWidget {
  const CompletedHeader({super.key, required this.title, required this.message});

  static const double _imageSize = 96;

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image(
              image: const AssetImage(SangaAssets.statusSuccess, package: SangaAssets.package),
              width: _imageSize,
              height: _imageSize,
            )
            .animate()
            .scaleXY(begin: 0.6, end: 1, duration: SangaMotion.sheetEnter, curve: SangaMotion.springDetail)
            .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
        const SizedBox(height: SangaSpacing.md),
        Text(title, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        const SizedBox(height: SangaSpacing.xs),
        Text(message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
      ],
    );
  }
}
