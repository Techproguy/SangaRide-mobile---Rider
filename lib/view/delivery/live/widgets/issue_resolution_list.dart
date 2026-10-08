import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueResolutionList extends StatelessWidget {
  const IssueResolutionList({super.key, required this.options, required this.selectedId, required this.onSelect});

  static const Map<String, IconData> _icons = {
    'reassign': Icons.person_add_alt_1_rounded,
    'return_to_sender': Icons.assignment_return_rounded,
    'cancel': Icons.cancel_outlined,
  };

  final List<DeliveryResolutionOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        Text('Resolution options', textAlign: TextAlign.center, style: SangaTextStyles.title),
        for (final option in options)
          SangaOptionCard(
            leading: SangaIconBadge(size: 36, child: Icon(_icons[option.id] ?? Icons.check_circle_outline_rounded)),
            title: option.label,
            subtitle: option.blurb.isEmpty ? null : option.blurb,
            isSelected: option.id == selectedId,
            onTap: () => onSelect(option.id),
          ),
      ],
    );
  }
}
