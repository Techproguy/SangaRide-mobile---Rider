import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryDeliveryCards extends StatelessWidget {
  const HistoryDeliveryCards({super.key, required this.delivery});

  static const double _proofAspect = 4 / 3;
  static const String _assetPrefix = 'assets/';

  final HistoryDelivery delivery;

  static ImageProvider proofImage(String url) => url.startsWith(_assetPrefix) ? AssetImage(url) : NetworkImage(url);

  @override
  Widget build(BuildContext context) {
    final proof = delivery.proofPhotoUrl;
    return Column(
      spacing: SangaSpacing.md,
      children: [
        SangaDetailList(
          title: 'Package details',
          rows: [
            SangaDetailRow(icon: Icons.inventory_2_outlined, label: 'Item', value: delivery.itemName),
            if (delivery.sizeSummary case final size?)
              SangaDetailRow(icon: Icons.straighten_rounded, label: 'Size', value: size),
            if (delivery.description case final notes?)
              SangaDetailRow(icon: Icons.notes_rounded, label: 'Notes', value: notes),
          ],
        ),
        SangaDetailList(
          title: 'Recipient details',
          rows: [
            SangaDetailRow(icon: Icons.person_outline_rounded, label: 'Name', value: delivery.recipientName),
            SangaDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: delivery.recipientPhone),
          ],
        ),
        if (proof != null)
          SangaSectionCard(
            title: 'Delivery proof',
            subtitle: 'The photo your driver took at drop off',
            children: [
              Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: ClipRRect(
                  borderRadius: SangaRadii.field,
                  child: AspectRatio(
                    aspectRatio: _proofAspect,
                    child: Image(
                      image: proofImage(proof),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const ColoredBox(
                        color: SangaColors.cardMuted,
                        child: Center(child: Icon(Icons.image_not_supported_outlined, color: SangaColors.textMuted)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
