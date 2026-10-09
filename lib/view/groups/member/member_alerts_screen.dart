import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberAlertsScreen extends StatelessWidget {
  const MemberAlertsScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: GroupCopy.alertsTitle,
      builder: (context, group, detail, member) => _Form(group: group, member: member),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.group, required this.member});

  final GroupController group;
  final GroupMember member;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late MemberAlerts _draft = widget.member.alerts;

  @override
  Widget build(BuildContext context) {
    final name = widget.member.firstName;
    return MemberSettingPage(
      title: GroupCopy.alertsTitle,
      group: widget.group,
      member: widget.member,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(alerts: _draft),
      ),
      children: [
        Text(GroupCopy.alertsLead(name), style: SangaTextStyles.body),
        MemberToggleList(
          rows: [
            MemberToggle(
              icon: Icons.play_circle_outline_rounded,
              title: GroupCopy.alertTitle(MemberAlertKind.tripStarted),
              subtitle: GroupCopy.alertBody(MemberAlertKind.tripStarted, name),
              value: _draft.tripStarted,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(tripStarted: value)),
            ),
            MemberToggle(
              icon: Icons.flag_outlined,
              title: GroupCopy.alertTitle(MemberAlertKind.tripEnded),
              subtitle: GroupCopy.alertBody(MemberAlertKind.tripEnded, name),
              value: _draft.tripEnded,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(tripEnded: value)),
            ),
            MemberToggle(
              icon: Icons.sos_rounded,
              title: GroupCopy.alertTitle(MemberAlertKind.sos),
              subtitle: GroupCopy.alertBody(MemberAlertKind.sos, name),
              value: _draft.sos,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(sos: value)),
            ),
            MemberToggle(
              icon: Icons.payments_outlined,
              title: GroupCopy.alertTitle(MemberAlertKind.overLimit),
              subtitle: GroupCopy.alertBody(MemberAlertKind.overLimit, name),
              value: _draft.overLimit,
              onChanged: (value) => setState(() => _draft = _draft.copyWith(overLimit: value)),
            ),
          ],
        ),
      ],
    );
  }
}
