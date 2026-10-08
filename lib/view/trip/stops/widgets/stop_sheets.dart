import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

Future<void> showStopUpdatingSheet(BuildContext context) {
  return showSangaSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: _statusPadding,
    builder: (_) => const PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.pending,
        title: 'Updating your trip',
        message: 'We’re working out your new route and fare',
      ),
    ),
  );
}

Future<bool> showStopFailureSheet(BuildContext context, AddStopFailure failure) {
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.failure,
    title: failure.title,
    message: failure.message,
    actionLabel: failure.primaryLabel,
    secondaryLabel: failure.secondaryLabel,
  );
}
