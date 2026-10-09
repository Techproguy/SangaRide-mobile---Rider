import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/verification/verification_copy.dart';
import 'package:sanga_ride/view/verification/widgets/verification_hero.dart';
import 'package:sanga_ride/view/verification/widgets/verification_item_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _controller = Get.find<VerificationController>();
  late final Worker _worker;
  VerificationStatus? _previous;

  @override
  void initState() {
    super.initState();
    _previous = _controller.status;
    _worker = ever(_controller.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.load());
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  void _onState(VerificationState state) {
    final verification = state.verificationOrNull;
    if (verification == null) return;
    final previous = _previous;
    _previous = verification.status;
    if (previous != VerificationStatus.pending || !mounted) return;
    if (verification.status == VerificationStatus.verified) unawaited(_celebrate());
    if (verification.status.needsAction) unawaited(_explainRejection(verification));
  }

  Future<void> _celebrate() {
    return showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: VerificationCopy.verifiedTitle,
      message: VerificationCopy.verifiedMessage,
      actionLabel: VerificationCopy.done,
    );
  }

  Future<void> _explainRejection(Verification verification) async {
    final reason = verification.actionItems.firstOrNull?.reason?.message;
    final isRetry = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      title: VerificationCopy.anotherGoTitle,
      message: reason ?? VerificationCopy.anotherGoMessage,
      actionLabel: VerificationCopy.tryAgain,
      secondaryLabel: VerificationCopy.notNow,
    );
    if (isRetry && mounted) _continue(verification);
  }

  void _continue(Verification verification) {
    final next = verification.nextItem;
    if (next != null) {
      unawaited(context.push(VerificationRoutes.itemOf(next)));
      return;
    }
    if (verification.isReadyToSubmit) {
      unawaited(_submit());
      return;
    }
    context.pop();
  }

  Future<void> _submit() async {
    final isSent = await _controller.submitReview();
    if (!mounted) return;
    if (!isSent) {
      SangaToast.show(
        _controller.draft.problem?.message ?? VerificationProblem.unknown.message,
        tone: SangaToastTone.error,
      );
    }
  }

  Widget _items(Verification verification) {
    final isLocked = verification.status == VerificationStatus.pending;
    return SangaListGroup(
      children: [
        for (final item in verification.items)
          VerificationItemTile(
            item: item,
            onTap: item.needsAction && !isLocked ? () => context.push(VerificationRoutes.itemOf(item)) : null,
          ),
      ],
    );
  }

  Widget _footer(Verification verification) {
    return Obx(() {
      final isSubmitting = _controller.isSubmitting;
      final isDone =
          verification.status == VerificationStatus.pending || verification.status == VerificationStatus.verified;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.xs,
        children: [
          SangaButton.primary(
            label: isDone ? VerificationCopy.done : VerificationCopy.primaryLabelOf(verification),
            isLoading: isSubmitting,
            onPressed: isDone ? () => context.pop() : () => _continue(verification),
          ),
          if (verification.status == VerificationStatus.pending)
            SangaTextLink(label: VerificationCopy.talkToSupport, onPressed: () => context.push(SupportRoutes.home)),
        ],
      );
    });
  }

  Widget _body(Verification verification) {
    final submittedAt = verification.submittedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        VerificationHero(
          status: verification.status,
          copy: VerificationCopy.heroOf(verification),
          submittedLine: verification.status == VerificationStatus.pending && submittedAt != null
              ? VerificationCopy.sentLine(TimeFormat.ago(submittedAt).toLowerCase())
              : null,
        ),
        _items(verification),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.state;
      final verification = state.verificationOrNull;
      return SangaPageLayout(
        title: VerificationCopy.centreTitle,
        footer: verification == null ? null : _footer(verification),
        children: [
          switch (state) {
            VerificationLoading() => const SangaSkeleton.heights([140, 56, 56]),
            VerificationFailed(:final problem) => SangaFailureMessage(
              message: problem.message,
              onRetry: _controller.retry,
            ),
            VerificationLoaded(:final verification) => _body(verification),
          },
        ],
      );
    });
  }
}
