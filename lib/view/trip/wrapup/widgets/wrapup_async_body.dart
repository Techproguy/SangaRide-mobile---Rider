import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WrapUpFailure {
  const WrapUpFailure({required this.title, required this.message, this.onRetry});

  final String title;
  final String message;
  final VoidCallback? onRetry;
}

class WrapUpAsyncBody extends StatelessWidget {
  const WrapUpAsyncBody({
    super.key,
    required this.isLoading,
    required this.failure,
    required this.builder,
    this.skeletonHeights = const [96, 64, 64],
  });

  final bool isLoading;
  final WrapUpFailure? failure;
  final WidgetBuilder builder;
  final List<double> skeletonHeights;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _Skeleton(heights: skeletonHeights);
    final failure = this.failure;
    if (failure != null) return _Failure(failure: failure);
    return Builder(builder: builder)
        .animate()
        .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
        .moveY(begin: SangaSpacing.sm, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.heights});

  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final height in heights)
          Container(
            height: height,
            decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
          ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure});

  final WrapUpFailure failure;

  @override
  Widget build(BuildContext context) {
    final onRetry = failure.onRetry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SangaSpacing.xxl),
      child: Column(
        spacing: SangaSpacing.md,
        children: [
          Column(
            spacing: SangaSpacing.xs,
            children: [
              Text(failure.title, textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
              Text(failure.message, textAlign: TextAlign.center, style: SangaTextStyles.body),
            ],
          ),
          if (onRetry != null) SangaButton.outline(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
