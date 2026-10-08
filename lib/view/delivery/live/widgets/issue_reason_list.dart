import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueReasonList extends StatelessWidget {
  const IssueReasonList({super.key, required this.selected, required this.onSelect, this.isEnabled = true});

  static const Map<DeliveryIssueReason, IconData> _icons = {
    DeliveryIssueReason.driverNotMoving: Icons.gps_off_rounded,
    DeliveryIssueReason.cannotReachDriver: Icons.phone_disabled_rounded,
    DeliveryIssueReason.wrongLocation: Icons.wrong_location_rounded,
    DeliveryIssueReason.extraPayment: Icons.payments_outlined,
    DeliveryIssueReason.unableToComplete: Icons.unpublished_outlined,
    DeliveryIssueReason.safety: Icons.shield_outlined,
    DeliveryIssueReason.other: Icons.info_outline_rounded,
  };

  final DeliveryIssueReason? selected;
  final ValueChanged<DeliveryIssueReason> onSelect;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isEnabled,
      child: Column(
        spacing: SangaSpacing.sm,
        children: [
          for (final reason in DeliveryIssueReason.values)
            SangaOptionCard(
              leading: SangaIconBadge(size: 36, child: Icon(_icons[reason])),
              title: reason.label,
              subtitle: reason.hint,
              isSelected: reason == selected,
              onTap: () => onSelect(reason),
            ),
        ],
      ),
    );
  }
}
