import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelBreakdownRows extends StatelessWidget {
  const CancelBreakdownRows({super.key, required this.review, required this.reason});

  final CancellationReview review;
  final CancelReason reason;

  String get _refundLabel {
    final refund = review.refund;
    if (refund == null) return 'Not applicable';
    return '${SangaMoney.naira(refund.amount)} to your ${refund.destination}';
  }

  @override
  Widget build(BuildContext context) {
    final feeStyle = SangaTextStyles.cardTitle.copyWith(
      color: review.hasFee ? SangaColors.dangerStrong : SangaColors.success,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        Text('Fare breakdown', style: SangaTextStyles.cardHeading),
        _Row(label: 'Cancellation fee', value: review.hasFee ? SangaMoney.naira(review.fee) : 'Free', style: feeStyle),
        _Row(label: 'Payment method', value: review.paymentMethod?.label ?? 'Not set yet'),
        _Row(label: 'Refund', value: _refundLabel),
        _Row(label: 'Reason', value: reason.summary),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        Expanded(flex: 2, child: Text(label, style: SangaTextStyles.cardSubtitle)),
        Expanded(
          flex: 3,
          child: Text(value, textAlign: TextAlign.end, style: style ?? SangaTextStyles.cardSubtitle),
        ),
      ],
    );
  }
}
