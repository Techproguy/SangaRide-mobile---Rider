import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupStartTile extends StatelessWidget {
  const GroupStartTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: SangaColors.primaryWash,
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: SangaColors.primary),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xl),
            child: Column(
              spacing: SangaSpacing.sm,
              children: [
                Icon(icon, size: 28, color: SangaColors.primary),
                Text(label, textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
