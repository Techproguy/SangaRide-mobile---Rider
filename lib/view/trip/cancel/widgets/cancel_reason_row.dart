import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelReasonRow extends StatelessWidget {
  const CancelReasonRow({super.key, required this.reason, required this.isSelected, required this.onTap});

  final CancelReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      button: true,
      excludeSemantics: true,
      label: reason.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
          child: Row(
            spacing: SangaSpacing.md,
            children: [
              Expanded(child: Text(reason.label, style: SangaTextStyles.cardTitle)),
              SangaRadio(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}
