import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/verification/verification_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationItemTile extends StatelessWidget {
  const VerificationItemTile({super.key, required this.item, required this.onTap});

  final VerificationItem item;
  final VoidCallback? onTap;

  bool get _isProblem => item.status == ItemStatus.rejected || item.status == ItemStatus.expired;

  Widget? get _trailing => switch (item.status) {
    ItemStatus.verified => const SangaTag.success(label: 'Verified'),
    ItemStatus.pending => const SangaTag.scheduled(label: 'In review', icon: Icons.hourglass_top_rounded),
    ItemStatus.rejected => const SangaTag.urgent(label: 'Try again', icon: Icons.error_outline_rounded),
    ItemStatus.expired => const SangaTag.urgent(label: 'Expired', icon: Icons.error_outline_rounded),
    ItemStatus.expiring => const SangaTag.warning(label: 'Expiring soon'),
    ItemStatus.missing => onTap == null ? null : SangaListRow.chevron,
  };

  @override
  Widget build(BuildContext context) {
    final trailing = _trailing;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.sm,
          children: [
            SangaIconBadge(size: 36, child: Icon(VerificationCopy.iconOf(item.kind))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xxs,
                children: [
                  Text(item.label, style: SangaTextStyles.cardTitle),
                  Text(
                    VerificationCopy.itemSubtitleOf(item),
                    style: SangaTextStyles.tileSubtitle.copyWith(color: _isProblem ? SangaColors.danger : null),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: SangaSpacing.xs),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }
}
