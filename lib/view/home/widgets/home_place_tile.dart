import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomePlaceTile extends StatelessWidget {
  const HomePlaceTile({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.onTap,
    this.caption,
  });

  static const double height = 88;
  static const double _iconBox = 32;
  static const double _captionHeight = 11;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(7));

  final String icon;
  final double iconSize;
  final String label;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: _radius,
        boxShadow: [BoxShadow(color: SangaColors.cardShadow, blurRadius: 15, offset: Offset(0, 3))],
      ),
      child: Material(
        color: SangaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: SangaColors.tileBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: _iconBox,
                    child: Center(child: SangaIcon(icon, size: iconSize)),
                  ),
                  const SizedBox(height: SangaSpacing.xxs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, style: SangaTextStyles.tileLabel),
                  ),
                  SizedBox(
                    height: _captionHeight,
                    child: caption == null
                        ? null
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              caption!,
                              style: SangaTextStyles.caption.copyWith(fontSize: 9, color: SangaColors.textFaint),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
