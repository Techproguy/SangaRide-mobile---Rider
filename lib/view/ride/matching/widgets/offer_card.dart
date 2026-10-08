import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.isLeaving,
    required this.isAccepting,
    required this.isBusy,
    required this.onIgnore,
    required this.onAccept,
  });

  final DriverOffer offer;
  final bool isLeaving;
  final bool isAccepting;
  final bool isBusy;
  final VoidCallback onIgnore;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final driver = offer.driver;
    final isAvailable = offer.isAvailable;
    final card = Opacity(
      opacity: isAvailable ? 1 : 0.55,
      child: SangaListGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(SangaSpacing.md),
            child: SangaPersonHeader(
              name: driver.name,
              rating: driver.rating,
              photo: driver.photo,
              isVerified: driver.isVerified,
              trailing: _EtaChip(minutes: offer.etaMinutes),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SangaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.md,
              children: [
                Text(_offerLine, style: SangaTextStyles.cardValue),
                Row(
                  spacing: SangaSpacing.md,
                  children: [
                    Expanded(
                      child: SangaButton.outline(
                        label: 'Ignore',
                        size: SangaButtonSize.compact,
                        onPressed: isBusy ? null : onIgnore,
                      ),
                    ),
                    Expanded(
                      child: SangaButton.primary(
                        label: 'Accept',
                        size: SangaButtonSize.compact,
                        isLoading: isAccepting,
                        onPressed: isBusy || !isAvailable ? null : onAccept,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return AnimatedSize(
      duration: SangaMotion.morph,
      curve: SangaMotion.fadeCurve,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(
          heightFactor: isLeaving ? 0 : 1,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: SangaSpacing.md),
            child: card
                .animate(target: isLeaving ? 1 : 0)
                .fade(begin: 1, end: 0, duration: SangaMotion.quick, curve: SangaMotion.fadeExitCurve),
          ),
        ),
      ),
    );
  }

  String get _offerLine {
    if (!offer.isAvailable) return 'No longer available';
    final counter = offer.counterOffer;
    return 'Counter offer: ${counter == null ? 'none' : SangaMoney.naira(counter)}';
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm),
      decoration: const BoxDecoration(color: SangaColors.fill, borderRadius: SangaRadii.digit),
      child: Text('$minutes min', style: SangaTextStyles.chip),
    );
  }
}
