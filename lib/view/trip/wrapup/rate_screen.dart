import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_rating_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_receipt_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/rating_comment_field.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/rating_driver_header.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/rating_tag_wrap.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RateScreen extends StatefulWidget {
  const RateScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final _receipt = Get.find<TripReceiptController>();
  final _rating = Get.find<TripRatingController>();
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating.open(widget.tripId);
    unawaited(_receipt.open(widget.tripId));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _home() => context.go(SangaRoutes.home);

  Future<void> _submit(OfferDriver driver) async {
    final isDone = await _rating.submit();
    if (!isDone || !mounted) return;
    Toast.success('Thanks for rating ${driver.firstName}');
    _home();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final receiptState = _receipt.state;
      final ratingState = _rating.state;
      final driver = receiptState is ReceiptLoaded ? receiptState.receipt.driver : null;
      final isSubmitting = ratingState is RatingSubmitting;
      return SangaPageLayout(
        title: 'Rate your driver',
        footer: Column(
          spacing: SangaSpacing.xs,
          children: [
            SangaButton.primary(
              label: 'Done',
              isLoading: isSubmitting,
              onPressed: driver != null && ratingState.rating.hasStars ? () => _submit(driver) : null,
            ),
            TextButton(
              onPressed: isSubmitting ? null : _home,
              child: Text('Skip', style: SangaTextStyles.label.copyWith(color: SangaColors.textMuted)),
            ),
          ],
        ),
        children: [
          WrapUpAsyncBody(
            isLoading: receiptState is ReceiptLoading,
            failure: switch (receiptState) {
              ReceiptFailed(:final reason) => WrapUpFailure(
                title: reason.title,
                message: reason.message,
                onRetry: reason.canRetry ? _receipt.reload : null,
              ),
              ReceiptLoading() || ReceiptLoaded() => null,
            },
            skeletonHeights: const [96, 24, 44, 120],
            builder: (context) => driver == null
                ? const SizedBox.shrink()
                : _RateBody(
                    driver: driver,
                    state: ratingState,
                    comment: _comment,
                    onStars: _rating.setStars,
                    onTag: _rating.toggleTag,
                    onComment: _rating.setComment,
                    onRetry: () => _submit(driver),
                  ),
          ),
        ],
      );
    });
  }
}

class _RateBody extends StatelessWidget {
  const _RateBody({
    required this.driver,
    required this.state,
    required this.comment,
    required this.onStars,
    required this.onTag,
    required this.onComment,
    required this.onRetry,
  });

  final OfferDriver driver;
  final RatingState state;
  final TextEditingController comment;
  final ValueChanged<int> onStars;
  final ValueChanged<RatingTag> onTag;
  final ValueChanged<String> onComment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final rating = state.rating;
    final isLocked = state is RatingSubmitting;
    return Column(
      spacing: SangaSpacing.lg,
      children: [
        RatingDriverHeader(driver: driver),
        Column(
          spacing: SangaSpacing.sm,
          children: [
            const Text('Select stars', style: SangaTextStyles.label),
            IgnorePointer(
              ignoring: isLocked,
              child: SangaStarInput(value: rating.stars, onChanged: onStars),
            ),
          ],
        ),
        AnimatedSize(
          duration: SangaMotion.morph,
          curve: SangaMotion.springBlock,
          alignment: Alignment.topCenter,
          child: rating.hasStars
              ? IgnorePointer(
                  ignoring: isLocked,
                  child: RatingTagWrap(tags: rating.availableTags, selected: rating.tags, onToggle: onTag),
                )
              : const SizedBox(width: double.infinity),
        ),
        RatingCommentField(controller: comment, onChanged: onComment, isEnabled: !isLocked),
        if (state is RatingFailed)
          SangaInlineMessage(
            title: RatingFailed.title,
            message: RatingFailed.message,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
      ],
    );
  }
}
