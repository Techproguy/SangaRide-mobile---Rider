import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideForListBody<T> extends StatelessWidget {
  const RideForListBody({
    super.key,
    required this.state,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.failedTitle,
    required this.onRetry,
    required this.builder,
  });

  final RideForListState<T> state;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String failedTitle;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, List<T> items) builder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RideForListLoading<T>() => const SangaSkeleton.list(),
      RideForListFailed<T>(:final problem) => SangaFailureMessage(
        title: failedTitle,
        message: problem.message,
        onRetry: onRetry,
      ),
      RideForListLoaded<T>(:final items) when items.isEmpty => SangaEmptyMessage(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      ),
      RideForListLoaded<T>(:final items) =>
        builder(context, items)
            .animate()
            .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
            .moveY(begin: SangaSpacing.sm, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock),
    };
  }
}
