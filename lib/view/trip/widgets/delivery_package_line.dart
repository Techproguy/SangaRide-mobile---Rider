import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryPackageLine extends StatelessWidget {
  const DeliveryPackageLine({super.key, required this.delivery});

  static const double _thumb = 44;

  final TripDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final item = delivery.item;
    final photo = item.photoUrl;
    return Row(
      spacing: SangaSpacing.sm,
      children: [
        SizedBox.square(
          dimension: _thumb,
          child: photo == null
              ? const SangaIconBadge(size: _thumb, child: Icon(Icons.inventory_2_outlined))
              : DeliveryPhoto(source: photo, aspectRatio: 1),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
              Text(
                [if (item.summary.isNotEmpty) item.summary, 'For ${delivery.recipient.firstName}'].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SangaTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
