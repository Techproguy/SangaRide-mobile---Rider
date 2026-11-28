import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueReasonList extends StatelessWidget {
  const IssueReasonList({
    super.key,
    required this.reasons,
    required this.selected,
    required this.onSelect,
    this.isEnabled = true,
  });

  static const Map<IssueIcon, IconData> _icons = {
    IssueIcon.notMoving: Icons.gps_off_rounded,
    IssueIcon.unreachable: Icons.phone_disabled_rounded,
    IssueIcon.location: Icons.wrong_location_rounded,
    IssueIcon.payment: Icons.payments_outlined,
    IssueIcon.incomplete: Icons.unpublished_outlined,
    IssueIcon.safety: Icons.shield_outlined,
  };

  final List<IssueType> reasons;
  final IssueType? selected;
  final ValueChanged<IssueType> onSelect;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isEnabled,
      child: Column(
        spacing: SangaSpacing.sm,
        children: [
          for (final reason in reasons)
            SangaOptionCard(
              leading: SangaIconBadge(size: 36, child: Icon(_icons[reason.icon] ?? Icons.info_outline_rounded)),
              title: reason.label,
              subtitle: reason.hint.isEmpty ? null : reason.hint,
              isSelected: reason.id == selected?.id,
              onTap: () => onSelect(reason),
            ),
        ],
      ),
    );
  }
}
