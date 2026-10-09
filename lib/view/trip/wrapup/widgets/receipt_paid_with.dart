import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReceiptPaidWith extends StatelessWidget {
  const ReceiptPaidWith({super.key, required this.paidWith, required this.paidAt});

  final ReceiptPayment paidWith;
  final DateTime paidAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SangaSpacing.md),
      decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
      child: Row(
        spacing: SangaSpacing.md,
        children: [
          SangaIconBadge(size: 40, child: Icon(PaymentMethodIcon.of(paidWith.method, groupKind: paidWith.group?.kind))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xxs,
              children: [
                const Text('Paid with', style: SangaTextStyles.cardSubtitle),
                Text(paidWith.label, style: SangaTextStyles.cardTitle),
                Text(formatRideSchedule(context, paidAt), style: SangaTextStyles.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
