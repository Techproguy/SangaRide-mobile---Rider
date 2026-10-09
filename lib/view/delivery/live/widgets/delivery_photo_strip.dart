import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryPhotoStrip extends StatelessWidget {
  const DeliveryPhotoStrip({super.key, required this.delivery});

  final TripDelivery delivery;

  List<({String label, String source})> get _photos => [
    if (delivery.senderConfirmation?.photoUrl case final String url) (label: 'Your photo', source: url),
    if (delivery.pickupProof?.photoUrl case final String url) (label: 'Pickup photo', source: url),
    if (delivery.deliveryProof?.photoUrl case final String url) (label: 'Delivery photo', source: url),
  ];

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        const SangaSectionHeader('Photos'),
        Row(
          spacing: SangaSpacing.sm,
          children: [
            for (final photo in photos)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SangaSpacing.xs,
                  children: [
                    DeliveryPhoto(
                      source: photo.source,
                      aspectRatio: 1,
                      onTap: () => showDeliveryPhotoViewer(context, photo.source),
                    ),
                    Text(photo.label, style: SangaTextStyles.cardSubtitle),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
