import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryTabBar extends StatelessWidget {
  const HistoryTabBar({super.key, required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) => SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter, vertical: SangaSpacing.md),
          child: Row(
            spacing: SangaSpacing.sm,
            children: [
              for (final (index, label) in labels.indexed)
                SangaChoiceChip(
                  label: label,
                  isSelected: controller.index == index,
                  onSelected: (_) => controller.animateTo(index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
