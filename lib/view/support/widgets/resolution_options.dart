import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ResolutionOptions extends StatelessWidget {
  const ResolutionOptions({super.key, required this.options, required this.selectedId, required this.onSelected});

  final List<ResolutionOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final option in options)
          SangaOptionCard(
            leading: const SangaIconBadge(size: 34, child: Icon(Icons.touch_app_outlined)),
            title: option.label,
            subtitle: option.hint.isEmpty ? null : option.hint,
            isSelected: option.id == selectedId,
            onTap: () => onSelected(option.id),
          ),
      ],
    );
  }
}
