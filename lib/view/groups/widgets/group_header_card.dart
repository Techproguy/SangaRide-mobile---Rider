import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupHeaderCard extends StatelessWidget {
  const GroupHeaderCard({super.key, required this.detail});

  final GroupDetail detail;

  String get _caption {
    final company = detail.company?.rcNumber;
    final count = GroupCopy.membersCount(detail.activeCount);
    return company == null ? count : GroupCopy.countWithCompany(count, company);
  }

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Row(
            spacing: SangaSpacing.md,
            children: [
              SangaIconBadge(size: 48, child: Icon(GroupCopy.icon(detail.kind))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SangaSpacing.xxs,
                  children: [
                    Text(detail.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardHeading),
                    Text(_caption, style: SangaTextStyles.cardSubtitle),
                  ],
                ),
              ),
              SangaTag.scheduled(label: detail.role.label, icon: Icons.shield_outlined),
            ],
          ),
        ),
      ],
    );
  }
}
