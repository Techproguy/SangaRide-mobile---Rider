import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

Future<bool> showCancelConfirmSheet(BuildContext context) async {
  final confirmed = await showSangaSheet<bool>(
    context: context,
    padding: _statusPadding,
    builder: (sheet) => SangaStatusContent(
      status: SangaStatus.failure,
      title: 'Cancel this ride?',
      message: 'You can’t undo this.',
      action: SangaButton.danger(label: 'Yes, cancel ride', onPressed: () => Navigator.of(sheet).pop(true)),
      secondary: SangaButton.muted(label: 'Keep ride', onPressed: () => Navigator.of(sheet).pop(false)),
    ),
  );
  return confirmed ?? false;
}

Future<void> showCancelledSheet(BuildContext context, CancelOutcome outcome) {
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.success,
    title: 'Ride cancelled',
    message: outcome.message,
    actionLabel: 'Back to home',
  );
}

Future<bool> showCancelFailureSheet(BuildContext context, CancelFailure failure) {
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.failure,
    title: failure.title,
    message: failure.message,
    actionLabel: failure.primaryLabel,
    secondaryLabel: failure.secondaryLabel,
  );
}
