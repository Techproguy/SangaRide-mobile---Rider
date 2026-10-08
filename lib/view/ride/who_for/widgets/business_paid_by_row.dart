import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BusinessPaidByRow extends StatelessWidget {
  const BusinessPaidByRow({super.key, required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SangaColors.primaryWash, borderRadius: SangaRadii.field),
      child: Padding(
        padding: const EdgeInsets.all(SangaSpacing.md),
        child: Row(
          spacing: SangaSpacing.md,
          children: [
            const SangaIconBadge(child: Icon(Icons.apartment_rounded)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xxs,
                children: [
                  Text('Paid by $companyName', style: SangaTextStyles.cardTitle),
                  const Text('This ride is billed to your company.', style: SangaTextStyles.cardSubtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
