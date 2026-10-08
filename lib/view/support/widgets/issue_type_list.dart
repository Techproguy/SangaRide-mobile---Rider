import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueTypeList extends StatelessWidget {
  const IssueTypeList({super.key, required this.types, required this.selectedId, required this.onSelected});

  final List<IssueType> types;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final type in types)
          SangaOptionCard(
            leading: SangaIconBadge(size: 34, child: Icon(SupportCopy.issueIconOf(type.icon))),
            title: type.label,
            subtitle: type.hint.isEmpty ? null : type.hint,
            isSelected: type.id == selectedId,
            onTap: () => onSelected(type.id),
          ),
      ],
    );
  }
}
