import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
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
    this.failureMessage,
  });

  final bool isLoading;
  final bool hasFailed;
  final String errorTitle;
  final VoidCallback onRetry;
  static final RxBool _alwaysObserved = false.obs;

  final WidgetBuilder builder;
  final int skeletonCount;
  final double skeletonHeight;
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return SangaSkeleton.list(count: skeletonCount, height: skeletonHeight);
    if (hasFailed) {
      return SangaFailureMessage(
        title: errorTitle,
        message: failureMessage ?? RideLoadProblem.connection.message,
        onRetry: onRetry,
      );
    }
    return Obx(() {
          _alwaysObserved.value;
          return builder(context);
        })
        .animate()
        .fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve)
        .moveY(begin: SangaSpacing.sm, end: 0, duration: SangaMotion.morph, curve: SangaMotion.springBlock);
  }
}
