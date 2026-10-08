import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOptionAsyncState extends StatelessWidget {
  const RideOptionAsyncState({
    super.key,
    required this.isLoading,
    required this.hasFailed,
    required this.errorTitle,
    required this.onRetry,
    required this.builder,
    this.skeletonCount = 3,
    this.skeletonHeight = 64,
  });

  final bool isLoading;
  final bool hasFailed;
  final String errorTitle;
  final VoidCallback onRetry;
  static final RxBool _alwaysObserved = false.obs;

  final WidgetBuilder builder;
  final int skeletonCount;
  final double skeletonHeight;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _Skeleton(count: skeletonCount, height: skeletonHeight);
    if (hasFailed) return _Failure(title: errorTitle, onRetry: onRetry);
    return Obx(() {
      _alwaysObserved.value;
      return builder(context);
    })
        .animate()
        .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
        .moveY(begin: SangaSpacing.sm, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.count, required this.height});

  final int count;
  final double height;

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

class _Failure extends StatelessWidget {
  const _Failure({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SangaSpacing.xxl),
      child: Column(
        spacing: SangaSpacing.md,
        children: [
          Column(
            spacing: SangaSpacing.xs,
            children: [
              Text(title, textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
              Text('Check your connection and try again.', textAlign: TextAlign.center, style: SangaTextStyles.body),
            ],
          ),
          SangaButton.outline(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
