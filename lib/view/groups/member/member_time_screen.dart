import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberTimeScreen extends StatelessWidget {
  const MemberTimeScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: GroupCopy.timeWindowTitle,
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
  static const String defaultFrom = '06:00';
  static const String defaultTo = '21:00';

  late bool _hasWindow = widget.member.limits.timeWindow != null;
  late String _from = widget.member.limits.timeWindow?.from ?? defaultFrom;
  late String _to = widget.member.limits.timeWindow?.to ?? defaultTo;

  Future<String?> _pick(String title, String current) async {
    final (hour, minute) = TimeWindow.decode(current);
    final picked = await showSangaTimeSheet(
      context: context,
      title: title,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    return picked == null ? null : TimeWindow.encode(picked.hour, picked.minute);
  }

  Future<void> _pickFrom() async {
    final value = await _pick(GroupCopy.ridesStartFrom, _from);
    if (value != null && mounted) setState(() => _from = value);
  }

  Future<void> _pickTo() async {
    final value = await _pick(GroupCopy.ridesRunUntil, _to);
    if (value != null && mounted) setState(() => _to = value);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final name = widget.member.firstName;
    final isValid = !_hasWindow || _from != _to;
    return MemberSettingPage(
      title: GroupCopy.timeWindowTitle,
      group: widget.group,
      member: widget.member,
      canSave: isValid,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(
          limits: widget.member.limits.copyWith(
            timeWindow: () => _hasWindow ? TimeWindow(from: _from, to: _to) : null,
          ),
        ),
      ),
      children: [
        SangaListGroup(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
              child: SangaToggleRow(
                leading: const SangaIconBadge(child: Icon(Icons.schedule_rounded)),
                title: GroupCopy.onlyAtSetTimes,
                subtitle: GroupCopy.outsideHours(name),
                value: _hasWindow,
                onChanged: (value) => setState(() => _hasWindow = value),
              ),
            ),
            if (_hasWindow)
              Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: SangaSpacing.sm,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: SangaSpacing.sm,
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: GroupCopy.from,
                            value: GroupCopy.clock(_from, localizations),
                            onTap: _pickFrom,
                          ),
                        ),
                        Expanded(
                          child: _TimeField(
                            label: GroupCopy.to,
                            value: GroupCopy.clock(_to, localizations),
                            onTap: _pickTo,
                          ),
                        ),
                      ],
                    ),
                    if (!isValid) const SangaFieldError(GroupCopy.pickTwoTimes),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        SangaFieldLabel(label),
        Material(
          color: SangaColors.fill,
          borderRadius: SangaRadii.field,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: SangaTextField.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
                child: Row(
                  spacing: SangaSpacing.xs,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: SangaColors.textMuted),
                    Text(value, style: SangaTextStyles.input),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
