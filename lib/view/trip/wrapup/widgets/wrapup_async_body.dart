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
    if (isLoading) return SangaSkeleton.heights(skeletonHeights);
    final failure = this.failure;
    if (failure != null) {
      return SangaFailureMessage(title: failure.title, message: failure.message, onRetry: failure.onRetry);
    }
    return Builder(builder: builder)
        .animate()
        .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
        .moveY(begin: SangaSpacing.sm, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock);
  }
}
