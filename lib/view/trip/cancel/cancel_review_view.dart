import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_breakdown_rows.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_vehicle_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelReviewView extends StatelessWidget {
  const CancelReviewView({
    super.key,
    required this.trip,
    required this.reason,
    required this.review,
    required this.isSubmitting,
    required this.onCancel,
    required this.onKeep,
    required this.onBack,
  });

  final Trip trip;
  final CancelReason reason;
  final CancellationReview review;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onKeep;
  final VoidCallback onBack;

  static const EdgeInsets _cell = EdgeInsets.all(SangaSpacing.md);

  String get _cancelLabel => review.hasFee ? 'Cancel ride · ${SangaMoney.naira(review.fee)}' : 'Cancel ride';

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Cancel ride',
      onBack: onBack,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: SangaSpacing.sm,
        children: [
          SangaButton.danger(label: _cancelLabel, isLoading: isSubmitting, onPressed: onCancel),
          SangaButton.muted(label: 'Keep my ride', onPressed: isSubmitting ? null : onKeep),
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
            if (reason.isSafety)
              const SangaNotice(
                message: 'If you feel unsafe right now, get help first',
                tone: SangaTone.neutral,
                icon: Icons.shield_outlined,
              ),
            if (review.hasFee) SangaNotice(message: review.feeReason.notice(SangaMoney.naira(review.fee))),
          ],
        ),
      ],
    );
  }
}
