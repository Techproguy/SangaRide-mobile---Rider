import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SearchingSheetContent extends StatelessWidget {
  const SearchingSheetContent({
    super.key,
    required this.steps,
    required this.doneCount,
    required this.continueAt,
    required this.isCancelling,
    this.isReconnecting = false,
    required this.onCancel,
    required this.onContinue,
  });

  final List<String> steps;
  final int doneCount;
  final DateTime? continueAt;
  final bool isCancelling;
  final bool isReconnecting;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SangaActivityIndicator(),
        const SizedBox(height: SangaSpacing.md),
        const Text('Finding your driver…', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        const SizedBox(height: SangaSpacing.xs),
        const Text(
          'We’re matching you with drivers nearby',
          textAlign: TextAlign.center,
          style: SangaTextStyles.statusMessage,
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaChecklist(items: steps, doneCount: doneCount),
        AnimatedSize(
          duration: SangaMotion.quick,
          curve: SangaMotion.springBlock,
          alignment: Alignment.topCenter,
          child: isReconnecting
              ? const Padding(
                  padding: EdgeInsets.only(top: SangaSpacing.md),
                  child: SangaNotice(
                    message: 'Reconnecting. We’re still looking for your driver.',
                    tone: SangaTone.warning,
                    icon: Icons.sync_rounded,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaButton.muted(label: 'Cancel request', isLoading: isCancelling, onPressed: onCancel),
        const SizedBox(height: SangaSpacing.sm),
        _SeeDriversButton(continueAt: continueAt, isDisabled: isCancelling, onContinue: onContinue),
      ],
    );
  }
}

class _SeeDriversButton extends StatelessWidget {
  const _SeeDriversButton({required this.continueAt, required this.isDisabled, required this.onContinue});

  final DateTime? continueAt;
  final bool isDisabled;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final endsAt = continueAt;
    if (endsAt == null) return const SangaButton.primary(label: 'See drivers');
    return SangaCountdown(
      endsAt: endsAt,
      onFinished: onContinue,
      builder: (context, remaining) {
        final seconds = (remaining.inMilliseconds / 1000).ceil();
        return SangaButton.primary(label: 'See drivers (${seconds}s)', onPressed: isDisabled ? null : onContinue);
      },
    );
  }
}
