import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<bool> showCancelScheduledSheet({
  required BuildContext context,
  required bool isRepeat,
  required String whenLabel,
}) async {
  final confirmed = await showSangaSheet<bool>(
    context: context,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isRepeat ? 'Cancel this repeat ride?' : 'Cancel this ride?',
          textAlign: TextAlign.center,
          style: SangaTextStyles.statusTitle,
        ),
        const SizedBox(height: SangaSpacing.xs),
        Text(
          isRepeat
              ? 'Every upcoming ride in this series will be cancelled. Your next one is $whenLabel.'
              : 'Your ride for $whenLabel will be cancelled.',
          textAlign: TextAlign.center,
          style: SangaTextStyles.statusMessage,
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaButton.danger(
          label: isRepeat ? 'Cancel repeat ride' : 'Cancel ride',
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: SangaSpacing.sm),
        SangaButton.outline(label: 'Keep it', onPressed: () => Navigator.of(context).pop(false)),
      ],
    ),
  );
  return confirmed ?? false;
}
