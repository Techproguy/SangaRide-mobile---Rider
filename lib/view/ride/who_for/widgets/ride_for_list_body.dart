import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideForListBody<T> extends StatelessWidget {
  const RideForListBody({
    super.key,
    required this.state,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.failedTitle,
    required this.onRetry,
    required this.builder,
  });

  final RideForListState<T> state;
  final String emptyTitle;
  final String emptyMessage;
  final String failedTitle;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, List<T> items) builder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RideForListLoading<T>() => const _Skeleton(),
      RideForListFailed<T>() => SangaInlineMessage(
        title: failedTitle,
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      RideForListLoaded<T>(:final items) when items.isEmpty => SangaInlineMessage(
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

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static const int count = 3;
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            height: height,
            decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
          ),
      ],
    );
  }
}
