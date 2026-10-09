import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelBreakdownRows extends StatelessWidget {
  const CancelBreakdownRows({super.key, required this.review, required this.reason});

  final CancellationReview review;
  final CancelReason reason;

  String get _refundLabel {
    final refund = review.refund;
    if (refund == null) return CancelCopy.notApplicable;
    return CancelCopy.refundTo(SangaMoney.naira(refund.amount), refund.destination);
  }

  @override
  Widget build(BuildContext context) {
    final feeStyle = SangaTextStyles.cardTitle.copyWith(
      color: review.hasFee ? SangaColors.danger : SangaColors.success,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        const SangaSectionHeader(CancelCopy.fareBreakdown),
        _Row(
          label: CancelCopy.cancellationFee,
          value: review.hasFee ? SangaMoney.naira(review.fee) : CancelCopy.free,
          style: feeStyle,
        ),
        _Row(label: CancelCopy.paymentMethod, value: review.paymentMethod?.label ?? CancelCopy.notSetYet),
        _Row(label: CancelCopy.refund, value: _refundLabel),
        _Row(label: CancelCopy.reason, value: reason.summary),
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
