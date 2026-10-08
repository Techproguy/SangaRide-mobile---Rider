import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReceiptDeliveryCard extends StatelessWidget {
  const ReceiptDeliveryCard({super.key, required this.delivery});

  final ReceiptDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final deliveredAt = delivery.deliveredAt;
    final proof = delivery.proofPhotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        SangaDetailList(
          title: 'Delivery',
          rows: [
            SangaDetailRow(icon: Icons.inventory_2_outlined, label: 'Package', value: delivery.itemName),
            SangaDetailRow(icon: Icons.person_outline_rounded, label: 'Delivered to', value: delivery.recipientName),
            if (deliveredAt != null) ...[
              SangaDetailRow(
                icon: Icons.schedule_rounded,
                label: 'Delivery time',
                value: DateFormat('h:mm a').format(deliveredAt),
              ),
              SangaDetailRow(
                icon: Icons.event_rounded,
                label: 'Date',
                value: DateFormat('EEE d MMM yyyy').format(deliveredAt),
              ),
            ],
            SangaDetailRow(icon: Icons.bolt_rounded, label: 'Delivery tier', value: delivery.tierLabel),
          ],
        ),
        if (proof != null)
          SangaSectionCard(
            title: 'Proof of delivery',
            children: [
              Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: DeliveryPhoto(source: proof, onTap: () => showDeliveryPhotoViewer(context, proof)),
              ),
            ],
          ),
      ],
    );
  }
}
