import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/delivery_package_line.dart';
import 'package:sanga_ride/view/trip/widgets/delivery_progress_bar.dart';
import 'package:sanga_ride/view/trip/widgets/trip_action_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_driver_header.dart';
import 'package:sanga_ride/view/trip/widgets/trip_eta_line.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryPanelActions {
  const DeliveryPanelActions({
    required this.onCall,
    required this.onMessage,
    required this.onSafety,
    required this.onShare,
    required this.onReportIssue,
    required this.onCancel,
    required this.onConfirmDetails,
    required this.onShowPin,
    required this.onReportMismatch,
    required this.onConfirmPickup,
    required this.onMakePayment,
    required this.onSeeDetails,
    required this.onSeeProof,
  });

  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onSafety;
  final VoidCallback onShare;
  final VoidCallback onReportIssue;
  final VoidCallback onCancel;
  final VoidCallback onConfirmDetails;
  final VoidCallback onShowPin;
  final VoidCallback onReportMismatch;
  final VoidCallback onConfirmPickup;
  final VoidCallback onMakePayment;
  final VoidCallback onSeeDetails;
  final VoidCallback onSeeProof;
}

class DeliveryTripPanel extends StatelessWidget {
  const DeliveryTripPanel({
    super.key,
    required this.trip,
    required this.delivery,
    required this.phase,
    required this.unreadCount,
    required this.actions,
  });

  final Trip trip;
  final TripDelivery delivery;
  final DeliveryPhase phase;
  final int unreadCount;
  final DeliveryPanelActions actions;

  Color get _statusColor => switch (phase.tone) {
    DeliveryPhaseTone.neutral => SangaColors.textPrimary,
    DeliveryPhaseTone.primary => SangaColors.primary,
    DeliveryPhaseTone.success => SangaColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        TripDriverHeader(driver: trip.driver),
        const TripPanelDivider(),
        DeliveryPackageLine(delivery: delivery),
        _status(),
        _tiles(),
        if (DeliveryProgressBar.isShownFor(phase)) DeliveryProgressBar(phase: phase),
        ..._buttons(),
      ],
    );
  }

  Widget _status() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xxs,
      children: [
        Text(phase.statusLine, style: SangaTextStyles.cardTitle.copyWith(color: _statusColor)),
        if (phase.showsEta) TripEtaLine(etaAt: trip.etaAt, distanceRemainingKm: trip.distanceRemainingKm),
      ],
    );
  }

  Widget _tiles() {
    return TripActionTiles(
      unreadCount: unreadCount,
      onCall: actions.onCall,
      onMessage: actions.onMessage,
      onShare: phase.index >= DeliveryPhase.onTheWay.index ? actions.onShare : null,
      onSafety: actions.onSafety,
      onReportIssue: phase.canReport ? actions.onReportIssue : null,
      onCancel: trip.canChange ? actions.onCancel : null,
    );
  }

  List<Widget> _buttons() {
    return switch (phase) {
      DeliveryPhase.heading || DeliveryPhase.checking => const [],
      DeliveryPhase.atPickup => [SangaButton.primary(label: 'Confirm details', onPressed: actions.onConfirmDetails)],
      DeliveryPhase.sharingPin => [
        SangaButton.primary(label: 'Show trip PIN', onPressed: actions.onShowPin),
        SangaButton.muted(label: 'Report an issue', onPressed: actions.onReportMismatch),
      ],
      DeliveryPhase.confirmPickup => [SangaButton.primary(label: 'Confirm pickup', onPressed: actions.onConfirmPickup)],
      DeliveryPhase.payment => [SangaButton.primary(label: 'Make payment', onPressed: actions.onMakePayment)],
      DeliveryPhase.onTheWay ||
      DeliveryPhase.atDropoff ||
      DeliveryPhase.verifying ||
      DeliveryPhase.returning => [SangaButton.primary(label: 'See details', onPressed: actions.onSeeDetails)],
      DeliveryPhase.handedOver => [SangaButton.primary(label: 'See delivery proof', onPressed: actions.onSeeProof)],
    };
  }
}
