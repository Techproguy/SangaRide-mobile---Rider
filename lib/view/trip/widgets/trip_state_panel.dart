import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/trip_panel_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripLoadingPanel extends StatelessWidget {
  const TripLoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripPanelBody(
      children: [
        SizedBox(height: SangaSpacing.md),
        Center(child: SangaActivityIndicator(size: 40)),
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
          SangaButton.muted(label: 'Back to home', onPressed: onHome)
        else
          SangaButton.primary(label: 'Back to home', onPressed: onHome),
      ],
    );
  }
}

class TripEndedPanel extends StatelessWidget {
  const TripEndedPanel({super.key, required this.reason, required this.onHome});

  final TripCancelReason reason;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return TripPanelBody(
      children: [
        Text(reason.title, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        Text(reason.message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
        SangaButton.primary(label: 'Back to home', onPressed: onHome),
      ],
    );
  }
}
