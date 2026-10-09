import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/member_avatar.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberSummary extends StatelessWidget {
  const MemberSummary({super.key, required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: SangaSpacing.md,
      children: [
        MemberAvatar(name: member.name, photoUrl: member.photoUrl, size: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardHeading),
              Text(GroupCopy.roleCaption(member), style: SangaTextStyles.cardSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
