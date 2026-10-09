import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberPermissionsScreen extends StatelessWidget {
  const MemberPermissionsScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: GroupCopy.permissionsTitle,
      builder: (context, group, detail, member) => _Form(group: group, kind: detail.kind, member: member),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.group, required this.kind, required this.member});

  final GroupController group;
  final GroupKind kind;
  final GroupMember member;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late MemberPermissions _draft = widget.member.permissions;

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final name = widget.member.firstName;
    return MemberSettingPage(
      title: GroupCopy.permissionsTitle,
      group: widget.group,
      member: widget.member,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(permissions: _draft),
      ),
      children: [
        Text(GroupCopy.permissionsLead(kind, name), style: SangaTextStyles.body),
        MemberToggleList(
          rows: [
            MemberToggle(
              icon: Icons.directions_car_filled_outlined,
              title: GroupCopy.bookRidesTitle,
              subtitle: GroupCopy.bookRidesBody(name),
              value: _draft.bookRides,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(bookRides: value)),
            ),
            MemberToggle(
              icon: Icons.group_add_outlined,
              title: GroupCopy.bookForOthersTitle,
              subtitle: GroupCopy.bookForOthersBody(kind, name),
              value: _draft.bookForOthers,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(bookForOthers: value)),
            ),
            MemberToggle(
              icon: Icons.account_balance_wallet_outlined,
              title: GroupCopy.useWalletTitle(kind),
              subtitle: GroupCopy.useWalletBody(kind, name),
              value: _draft.useGroupWallet,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(useGroupWallet: value)),
            ),
          ],
        ),
      ],
    );
  }
}
