import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripPanelBody extends StatelessWidget {
  const TripPanelBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: children,
    ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve);
  }
}

class TripPanelDivider extends StatelessWidget {
  const TripPanelDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: SangaColors.cardBorder);
}
