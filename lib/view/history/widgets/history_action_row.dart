import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_action.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryActionRow extends StatelessWidget {
  const HistoryActionRow({super.key, required this.action, required this.onTap, this.isBusy = false});

  static const double _chip = 34;

  final HistoryAction action;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? SangaColors.dangerStrong : SangaColors.primary;
    final wash = action.isDestructive ? SangaColors.dangerSoft : SangaColors.primaryTint;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: SangaRadii.field,
        boxShadow: [BoxShadow(color: SangaColors.cardShadow, blurRadius: 16, offset: Offset(0, 3))],
      ),
      child: Material(
        color: SangaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: SangaColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm),
            child: Row(
              spacing: SangaSpacing.sm,
              children: [
                Container(
                  width: _chip,
                  height: _chip,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: wash,
                    borderRadius: SangaRadii.digit,
                    border: Border.all(color: color, width: 0.5),
                  ),
                  child: Icon(action.icon, size: 18, color: color),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(action.label, style: SangaTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)),
                      Text(action.subtitle, style: SangaTextStyles.cardSubtitle),
                    ],
                  ),
                ),
                if (isBusy) SangaListRow.spinner else SangaListRow.chevron,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
