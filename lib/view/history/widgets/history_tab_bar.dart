import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryTabBar extends StatelessWidget {
  const HistoryTabBar({super.key, required this.controller, required this.labels});

  static const double _indicatorWidth = 2;

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.sm),
      labelPadding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: SangaColors.primary, width: _indicatorWidth),
      ),
      dividerColor: SangaColors.divider,
      labelColor: SangaColors.primary,
      unselectedLabelColor: SangaColors.textFaint,
      labelStyle: SangaTextStyles.label,
      unselectedLabelStyle: SangaTextStyles.label,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      tabs: [for (final label in labels) Tab(text: label)],
    );
  }
}
