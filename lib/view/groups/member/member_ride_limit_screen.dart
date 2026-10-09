import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberRideLimitScreen extends StatelessWidget {
  const MemberRideLimitScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: GroupCopy.rideLimitTitle,
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
  static const int defaultLimit = 3;
  static const int maximum = 20;

  late bool _hasLimit = widget.member.limits.ridesPerDay != null;
  late int _perDay = widget.member.limits.ridesPerDay ?? defaultLimit;

  String get _valueLabel => GroupCopy.rideCount(_perDay);

  @override
  Widget build(BuildContext context) {
    final name = widget.member.firstName;
    return MemberSettingPage(
      title: GroupCopy.rideLimitTitle,
      group: widget.group,
      member: widget.member,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(limits: widget.member.limits.copyWith(ridesPerDay: () => _hasLimit ? _perDay : null)),
      ),
      children: [
        SangaListGroup(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
              child: SangaToggleRow(
                leading: const SangaIconBadge(child: Icon(Icons.directions_car_filled_outlined)),
                title: GroupCopy.limitRidesPerDay,
                subtitle: GroupCopy.capRides(name),
                value: _hasLimit,
                onChanged: (value) => setState(() => _hasLimit = value),
              ),
            ),
            if (_hasLimit)
              Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: SangaCounterField(
                  label: GroupCopy.ridesPerDay,
                  icon: Icons.directions_car_filled_outlined,
                  valueLabel: _valueLabel,
                  value: _perDay,
                  min: 1,
                  max: maximum,
                  onChanged: (value) => setState(() => _perDay = value),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
