import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReviewEditButton extends StatelessWidget {
  const ReviewEditButton({super.key, required this.label, required this.onPressed});

  static const double _size = 40;

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: SangaColors.primary,
        backgroundColor: SangaColors.primaryWash,
        minimumSize: const Size.square(_size),
        fixedSize: const Size.square(_size),
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.digit,
          side: BorderSide(color: SangaColors.primary, width: 0.5),
        ),
      ),
    );
  }
}
