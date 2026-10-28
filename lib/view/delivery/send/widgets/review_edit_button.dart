import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReviewEditButton extends StatelessWidget {
  const ReviewEditButton({super.key, required this.label, required this.onPressed});

  static const double _size = 35;
  static const double _iconSize = 17;
  static const double _borderWidth = 0.7;
  static const int _tintAlpha = 0x24;

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SangaColors.primary.withAlpha(_tintAlpha),
            borderRadius: SangaRadii.digit,
            border: Border.all(color: SangaColors.primary, width: _borderWidth),
          ),
          child: const Icon(Icons.edit_rounded, size: _iconSize, color: SangaColors.primary),
        ),
      ),
    );
  }
}
