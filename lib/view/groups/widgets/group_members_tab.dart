import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/member_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({
    super.key,
    required this.detail,
    required this.myId,
    required this.canManageMember,
    required this.onRefresh,
    required this.onInvite,
    required this.onOpenMember,
    required this.onLeave,
  });

  final GroupDetail detail;
  final String? myId;
  final bool Function(GroupMember member) canManageMember;
  final Future<void> Function() onRefresh;
  final VoidCallback onInvite;
  final ValueChanged<GroupMember> onOpenMember;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return SangaRefreshList.children(
      onRefresh: onRefresh,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            if (detail.canManage)
              SangaListGroup(
                children: [
                  SangaListRow(
                    leading: const SangaIconBadge(size: 40, child: Icon(Icons.person_add_alt_1_rounded)),
                    title: GroupCopy.inviteSomeone,
                    subtitle: GroupCopy.inviteHow,
                    onTap: onInvite,
                  ),
                ],
              ),
            SangaListGroup(
              children: [
                for (final member in detail.members)
                  MemberRow(
                    member: member,
                    isYou: member.id == myId,
                    onTap: canManageMember(member) ? () => onOpenMember(member) : null,
                  ),
              ],
            ),
            SangaTextAction(label: GroupCopy.leaveTitle(detail.kind), onPressed: onLeave, isDestructive: true),
          ],
        ),
      ],
    );
  }
}
