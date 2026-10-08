import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PackageDetailsCard extends StatelessWidget {
  const PackageDetailsCard({super.key, required this.delivery});

  final TripDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final item = delivery.item;
    final declaredValue = item.declaredValue;
    return SangaDetailList(
      title: 'Package details',
      rows: [
        SangaDetailRow(icon: Icons.inventory_2_outlined, label: delivery.kind.label, value: item.name),
        if (item.summary.isNotEmpty) SangaDetailRow(icon: Icons.straighten_rounded, label: 'Size', value: item.summary),
        if (declaredValue != null)
          SangaDetailRow(
            icon: Icons.verified_user_outlined,
            label: 'Declared value',
            value: SangaMoney.naira(declaredValue),
          ),
        SangaDetailRow(icon: Icons.person_outline_rounded, label: 'Recipient', value: delivery.recipient.name),
      ],
    );
  }
}
