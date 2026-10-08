import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ProfileFieldTile extends StatelessWidget {
  const ProfileFieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.edit_rounded,
    this.isEmpty = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit $label',
      excludeSemantics: true,
      child: Material(
        color: SangaColors.fill,
        borderRadius: SangaRadii.field,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm + 2),
            child: Row(
              spacing: SangaSpacing.sm,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SangaSpacing.xxs,
                    children: [
                      Text(label, style: SangaTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SangaTextStyles.cardSubtitle.copyWith(
                          color: isEmpty ? SangaColors.primary : SangaColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, size: 18, color: SangaColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
