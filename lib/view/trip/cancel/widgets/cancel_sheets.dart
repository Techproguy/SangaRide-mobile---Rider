import 'package:flutter/material.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

Future<bool> showCancelConfirmSheet(BuildContext context, CancelCopy copy) async {
  final confirmed = await showSangaSheet<bool>(
    context: context,
    padding: _statusPadding,
    builder: (sheet) => SangaStatusContent(
      status: SangaStatus.caution,
      title: copy.confirmTitle,
      message: 'You can’t undo this.',
      action: SangaButton.danger(label: copy.confirmAction, onPressed: () => Navigator.of(sheet).pop(true)),
      secondary: SangaButton.muted(label: copy.confirmKeep, onPressed: () => Navigator.of(sheet).pop(false)),
    ),
  );
  return confirmed ?? false;
}

Future<void> showCancelledSheet(BuildContext context, CancelOutcome outcome, CancelCopy copy) {
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.success,
    title: copy.doneTitle,
    message: outcome.message,
    actionLabel: CommonCopy.backToHome,
  );
}

Future<bool> showCancelFailureSheet(BuildContext context, CancelFailure failure) {
  return showSangaStatusSheet(
    context: context,
    status: failure.isStale || failure == CancelFailure.outcomeUnknown ? SangaStatus.caution : SangaStatus.failure,
    title: failure.title,
    message: failure.message,
    actionLabel: failure.primaryLabel,
    secondaryLabel: failure.secondaryLabel,
  );
}

Future<void> showCancelSettledSheet(BuildContext context, CancelSettled settled) {
  return showSangaStatusSheet(
    context: context,
    status: settled.isCancelled ? SangaStatus.success : SangaStatus.caution,
    title: settled.failure.title,
    message: settled.message ?? settled.failure.message,
    actionLabel: settled.isCancelled ? CommonCopy.backToHome : 'Got it',
  );
}
