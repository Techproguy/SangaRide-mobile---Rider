import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReviewEditButton extends StatelessWidget {
  const ReviewEditButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      button: true,
      child: SangaTextLink(label: 'Edit', onPressed: onPressed),
    );
  }
}
