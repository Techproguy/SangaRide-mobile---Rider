import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/cancel_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/cancel_reasons_view.dart';
import 'package:sanga_ride/view/trip/cancel/cancel_review_view.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_copy.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_sheets.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelScreen extends StatefulWidget {
  const CancelScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<CancelScreen> createState() => _CancelScreenState();
}

class _CancelScreenState extends State<CancelScreen> {
  final _cancel = Get.find<CancelController>();
  final _trip = Get.find<TripController>();
  late final Worker _worker;

  CancelCopy get _copy => CancelCopy.of(isDelivery: _trip.trip?.isDelivery ?? false);

  @override
  void initState() {
    super.initState();
    _worker = ever(_cancel.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cancel.open(widget.tripId));
  }

  @override
  void dispose() {
    _worker.dispose();
    scheduleMicrotask(_cancel.reset);
    super.dispose();
  }

  void _onState(CancelState next) {
    if (!mounted) return;
    switch (next) {
      case CancelFailed():
        unawaited(_showFailure(next.failure));
      case CancelSettled():
        unawaited(_showSettled(next));
      case CancelDone():
        unawaited(_showDone(next.outcome));
      default:
        break;
    }
  }

  Future<void> _showFailure(CancelFailure failure) async {
    final isPrimary = await showCancelFailureSheet(context, failure);
    if (!mounted) return;
    if (_cancel.resolveFailure(isPrimary: isPrimary)) context.pop();
  }

  Future<void> _showSettled(CancelSettled settled) async {
    await showCancelSettledSheet(context, settled);
    if (!mounted) return;
    if (settled.isCancelled) {
      context.go(SangaRoutes.home);
    } else {
      context.pop();
    }
  }

  Future<void> _showDone(CancelOutcome outcome) async {
    await showCancelledSheet(context, outcome, _copy);
    if (mounted) context.go(SangaRoutes.home);
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showCancelConfirmSheet(context, _copy);
    if (confirmed && mounted) unawaited(_cancel.submit());
  }

  void _handleBack(CancelState state) {
    if (state is CancelReviewing) {
      _cancel.backToReasons();
    } else if (!_cancel.isBusy) {
      context.pop();
    }
  }

  Widget _body(Trip trip, CancelState state) {
    return switch (state) {
      CancelReviewing(:final reason, :final review, :final isSubmitting, :final feeWas) => CancelReviewView(
        feeWas: feeWas,
        copy: CancelCopy.of(isDelivery: trip.isDelivery),
        trip: trip,
        reason: reason,
        review: review,
        isSubmitting: isSubmitting,
        onCancel: () => unawaited(_confirmCancel()),
        onKeep: context.pop,
        onBack: () => _handleBack(state),
      ),
      CancelFailed(:final previous) => _body(trip, previous),
      CancelLoadingReview(:final reason, :final note) => _reasons(trip, reason, note, isLoading: true),
      CancelChoosing(:final reason, :final note, :final canContinue) => _reasons(
        trip,
        reason,
        note,
        canContinue: canContinue,
      ),
      CancelSettled() || CancelDone() => _reasons(trip, null, '', isLoading: true),
    };
  }

  Widget _reasons(Trip trip, CancelReason? reason, String note, {bool canContinue = false, bool isLoading = false}) {
    return CancelReasonsView(
      copy: CancelCopy.of(isDelivery: trip.isDelivery),
      reasons: CancelReason.availableFor(trip.status),
      reason: reason,
      note: note,
      canContinue: canContinue,
      isLoading: isLoading,
      onSelect: _cancel.selectReason,
      onNote: _cancel.setNote,
      onContinue: () => unawaited(_cancel.loadReview()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TripPageGate(
      tripId: widget.tripId,
      title: _copy.title,
      child: Obx(() {
        final trip = _trip.trip;
        final state = _cancel.state;
        if (trip == null) {
          return SangaPageLayout(title: _copy.title, children: const [SangaSkeleton.heights([120, 64, 64, 64])]);
        }
        return PopScope(
          canPop: state is CancelChoosing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(state);
          },
          child: _body(trip, state),
        );
      }),
    );
  }
}
