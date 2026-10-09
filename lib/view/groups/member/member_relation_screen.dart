import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberRelationScreen extends StatelessWidget {
  const MemberRelationScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: 'Relation',
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
  late String _relation = widget.member.relation;

  List<String> get _options {
    final options = GroupCopy.relations(widget.kind);
    return options.contains(widget.member.relation) ? options : [widget.member.relation, ...options];
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.member.firstName;
    return MemberSettingPage(
      title: 'Relation',
      group: widget.group,
      member: widget.member,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(relation: _relation),
      ),
      children: [
        Text('Who is $name to you?', style: SangaTextStyles.body),
        SangaChoiceChips<String>(
          options: [for (final option in _options) SangaSelectOption(option, option)],
          value: _relation,
          onChanged: (relation) => setState(() => _relation = relation),
        ),
      ],
    );
  }
}
