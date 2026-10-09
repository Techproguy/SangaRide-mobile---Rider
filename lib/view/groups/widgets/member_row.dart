import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/member_avatar.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberRow extends StatelessWidget {
  const MemberRow({super.key, required this.member, required this.isYou, this.onTap});

  final GroupMember member;
  final bool isYou;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SangaListRow(
      leading: MemberAvatar(name: member.name, photoUrl: member.photoUrl),
      title: isYou ? GroupCopy.youSuffix(member.name) : member.name,
      subtitle: GroupCopy.roleCaption(member),
      trailing: onTap == null ? null : SangaListRow.chevron,
      onTap: onTap,
    );
  }
}
