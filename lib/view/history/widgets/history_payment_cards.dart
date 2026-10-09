import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride/view/history/widgets/history_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryPaymentCards extends StatelessWidget {
  const HistoryPaymentCards({super.key, required this.detail});

  final HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final paidWith = detail.paidWith;
    final counterOffer = detail.counterOffer;
    final distance = detail.distanceLabel;
    final duration = detail.durationLabel;
    return Column(
      spacing: SangaSpacing.md,
      children: [
        if (detail.lines.isNotEmpty)
          SangaFareBreakdown(
            title: 'Fare breakdown',
            lines: [for (final line in detail.lines) SangaFareLine(line.label, SangaMoney.naira(line.amount))],
            totalLabel: 'TOTAL PAID',
            total: SangaMoney.naira(detail.fare),
          ),
        SangaDetailList(
          title: 'Trip details',
          rows: [
            if (paidWith != null)
              SangaDetailRow(
                icon: PaymentMethodIcon.of(paidWith.method, groupKind: paidWith.group?.kind),
                label: 'Paid with',
                value: paidWith.label,
              ),
            if (counterOffer != null)
              SangaDetailRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Counter offer',
                value: SangaMoney.naira(counterOffer),
              ),
            SangaDetailRow(icon: Icons.event_rounded, label: 'Date', value: formatHistoryDate(detail.occurredAt)),
            if (distance != null) SangaDetailRow(icon: Icons.route_outlined, label: 'Distance', value: distance),
            if (duration != null) SangaDetailRow(icon: Icons.schedule_rounded, label: 'Duration', value: duration),
            SangaDetailRow(icon: Icons.tag_rounded, label: 'Reference', value: detail.reference),
          ],
        ),
      ],
    );
  }
}
