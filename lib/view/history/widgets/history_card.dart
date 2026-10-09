import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/view/history/widgets/history_delivery_cards.dart';
import 'package:sanga_ride/view/history/widgets/rebook_button.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.item, required this.whenLabel, required this.onTap, this.onRebook});

  static const double _visualWidth = 84;
  static const double _packageSize = 56;

  final HistoryItem item;
  final String whenLabel;
  final VoidCallback onTap;
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: SangaRadii.field,
        boxShadow: [BoxShadow(color: SangaColors.cardShadow, blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Material(
        color: SangaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: SangaColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SangaSpacing.md),
            child: IntrinsicHeight(
              child: Row(
                spacing: SangaSpacing.md,
                children: [
                  _visual(),
                  const VerticalDivider(width: 1, thickness: 1, color: SangaColors.divider),
                  Expanded(child: _details()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visual() {
    return SizedBox(
      width: _visualWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: SangaSpacing.xs,
        children: [
          if (item.kind.isDelivery) _packageVisual() else Image(image: item.category.image, fit: BoxFit.contain),
          Text(SangaMoney.naira(item.fare), style: SangaTextStyles.cardValue),
        ],
      ),
    );
  }

  Widget _packageVisual() {
    final photo = item.packagePhotoUrl;
    return ClipRRect(
      borderRadius: SangaRadii.field,
      child: Image(
        image: photo == null ? const AssetImage(AppAssets.serviceDelivery) : HistoryDeliveryCards.proofImage(photo),
        width: _visualWidth,
        height: _packageSize,
        fit: photo == null ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (context, error, stack) => const Image(
          image: AssetImage(AppAssets.serviceDelivery),
          width: _visualWidth,
          height: _packageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _details() {
    final isCancelled = item.status == HistoryStatus.cancelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.xs,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xxs,
                children: [
                  Text(whenLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
                  if (isCancelled) const SangaTag.urgent(label: 'Cancelled', icon: Icons.close_rounded),
                  if (item.status == HistoryStatus.unknown)
                    const SangaTag.scheduled(label: 'Updating', icon: Icons.sync_rounded),
                  if (item.memberName case final name?) _who(name),
                ],
              ),
            ),
            if (onRebook != null) RebookButton(onPressed: onRebook!),
          ],
        ),
        _stop(SangaStopKind.pickup, item.route.pickup.name, item.route.pickup.address),
        _stop(SangaStopKind.dropoff, item.route.dropoff.name, item.route.dropoff.address),
      ],
    );
  }

  Widget _who(String name) {
    final purpose = item.purpose;
    return Row(
      spacing: SangaSpacing.xxs,
      children: [
        const Icon(Icons.person_outline_rounded, size: 14, color: SangaColors.primary),
        Flexible(
          child: Text(
            purpose == null ? name : '$name · $purpose',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SangaTextStyles.tileSubtitle.copyWith(color: SangaColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _stop(SangaStopKind kind, String name, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        SangaStopPin(kind, size: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.tileSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
