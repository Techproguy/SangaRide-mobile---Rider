import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_breakdown_rows.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_copy.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_vehicle_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelReviewView extends StatelessWidget {
  const CancelReviewView({
    super.key,
    required this.copy,
    required this.trip,
    required this.reason,
    required this.review,
    required this.isSubmitting,
    required this.onCancel,
    required this.onKeep,
    required this.onBack,
    this.feeWas,
  });

  final CancelCopy copy;
  final Trip trip;
  final CancelReason reason;
  final CancellationReview review;
  final bool isSubmitting;
  final int? feeWas;
  final VoidCallback onCancel;
  final VoidCallback onKeep;
  final VoidCallback onBack;

  static const EdgeInsets _cell = EdgeInsets.all(SangaSpacing.md);

  String get _cancelLabel => review.hasFee ? '${copy.title} · ${SangaMoney.naira(review.fee)}' : copy.title;

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: copy.title,
      onBack: onBack,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          SangaButton.danger(label: _cancelLabel, isLoading: isSubmitting, onPressed: onCancel),
          SangaButton.muted(label: copy.keepLabel, onPressed: isSubmitting ? null : onKeep),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            SangaListGroup(
              children: [
                Padding(
                  padding: _cell,
                  child: Column(
                    spacing: SangaSpacing.sm,
                    children: [
                      TripDriverHeader(driver: trip.driver),
                      TripVehicleCard(trip: trip),
                    ],
                  ),
                ),
                Padding(
                  padding: _cell,
                  child: SangaRouteSummary(
                    pickup: trip.pickup.name,
                    dropoff: trip.dropoff.name,
                    stops: [for (final stop in trip.stops) stop.name],
                  ),
                ),
                Padding(
                  padding: _cell,
                  child: CancelBreakdownRows(review: review, reason: reason),
                ),
              ],
            ),
            if (feeWas != null && feeWas != review.fee)
              SangaNotice(
                message: 'The fee changed from ${SangaMoney.naira(feeWas!)} to ${SangaMoney.naira(review.fee)}. Take a look before you cancel.',
                tone: SangaTone.warning,
              ),
            if (reason.isSafety)
              const SangaNotice(
                message: 'If you feel unsafe right now, get help first',
                tone: SangaTone.neutral,
                icon: Icons.shield_outlined,
              ),
            if (review.hasFee) SangaNotice(message: review.notice(SangaMoney.naira(review.fee))),
          ],
        ),
      ],
    );
  }
}
