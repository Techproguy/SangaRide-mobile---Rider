import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/stops/widgets/fare_change_note.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class StopQuoteView extends StatelessWidget {
  const StopQuoteView({
    super.key,
    required this.quote,
    required this.isRefreshed,
    required this.isApplying,
    required this.onConfirm,
    required this.onKeep,
    required this.onBack,
  });

  final StopQuote quote;
  final bool isRefreshed;
  final bool isApplying;
  final VoidCallback onConfirm;
  final VoidCallback onKeep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Updated fare',
      onBack: onBack,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          SangaButton.primary(label: 'Confirm', isLoading: isApplying, onPressed: onConfirm),
          SangaButton.muted(label: 'Keep my trip', onPressed: isApplying ? null : onKeep),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            if (isRefreshed)
              const SangaNotice(
                message: 'Your fare moved, so we checked it again. Take a quick look before you confirm.',
                tone: SangaTone.neutral,
                icon: Icons.info_outline_rounded,
              ),
            FareChangeNote(currentTotal: quote.currentTotal, newTotal: quote.total),
            SangaFareBreakdown(
              title: 'Estimated fare',
              lines: [for (final line in quote.lines) SangaFareLine(line.label, SangaMoney.naira(line.amount))],
              totalLabel: 'NEW TOTAL',
              total: SangaMoney.naira(quote.total),
            ),
          ],
        ),
      ],
    );
  }
}
