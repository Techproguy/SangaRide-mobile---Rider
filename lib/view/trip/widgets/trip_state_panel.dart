import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_action_tiles.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripLoadingPanel extends StatelessWidget {
  const TripLoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripPanelBody(
      children: [
        SizedBox(height: SangaSpacing.md),
        Center(child: SangaActivityIndicator.content(size: 32)),
        SizedBox(height: SangaSpacing.md),
      ],
    );
  }
}

class TripFailedPanel extends StatelessWidget {
  const TripFailedPanel({super.key, required this.reason, required this.onRetry, required this.onHome});

  final TripLoadFailure reason;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        Text(reason.title, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        Text(reason.message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
        if (reason.canRetry) SangaButton.primary(label: 'Try again', onPressed: onRetry),
        if (reason.canRetry)
          SangaButton.muted(label: SangaCommonCopy.backToHome, onPressed: onHome)
        else
          SangaButton.primary(label: SangaCommonCopy.backToHome, onPressed: onHome),
      ],
    );
  }
}

class TripUpdatingPanel extends StatelessWidget {
  const TripUpdatingPanel({
    super.key,
    required this.unreadCount,
    required this.onCall,
    required this.onMessage,
    required this.onSafety,
  });

  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        const SangaActivityIndicator(size: 32),
        Text('Updating your trip', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        Text(
          'Hang tight while we check on your ride.',
          textAlign: TextAlign.center,
          style: SangaTextStyles.statusMessage,
        ),
        TripActionTiles(unreadCount: unreadCount, onCall: onCall, onMessage: onMessage, onSafety: onSafety),
      ],
    );
  }
}

class TripEndedPanel extends StatelessWidget {
  const TripEndedPanel({
    super.key,
    required this.reason,
    required this.onHome,
    this.message,
    this.returnFee,
    this.cancellationFee,
  });

  final TripCancelReason reason;
  final VoidCallback onHome;
  final String? message;
  final Money? returnFee;
  final Money? cancellationFee;

  @override
  Widget build(BuildContext context) {
    final fee = returnFee;
    final cancelFee = cancellationFee;
    return TripPanelBody(
      children: [
        Center(
          child: SangaToneCircle(
            icon: reason.didNotHappen ? Icons.block_rounded : Icons.info_outline_rounded,
            tone: reason.didNotHappen ? SangaMessageTone.danger : SangaMessageTone.warning,
          ),
        ),
        Text(reason.title, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        Text(message ?? reason.message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
        if (fee != null && fee.isPositive)
          SangaDetailList(
            title: 'Return fee',
            rows: [SangaDetailRow(icon: Icons.undo_rounded, label: 'Charged for the way back', value: fee.format())],
          ),
        if (cancelFee != null && cancelFee.isPositive)
          SangaDetailList(
            title: 'Fee',
            rows: [
              SangaDetailRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Taken from your wallet',
                value: cancelFee.format(),
              ),
            ],
          ),
        SangaButton.primary(label: SangaCommonCopy.backToHome, onPressed: onHome),
      ],
    );
  }
}
