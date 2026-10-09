import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberSpendingScreen extends StatelessWidget {
  const MemberSpendingScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: 'Spending limit',
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
  static const int minimum = 1000;
  static const int maxDigits = 8;
  static final NumberFormat _grouped = NumberFormat('#,##0', 'en_NG');

  final _amount = TextEditingController();
  late bool _hasLimit = widget.member.limits.monthlySpend != null;
  late int? _value = widget.member.limits.monthlySpend;
  late OverLimitAction _action = widget.member.limits.overLimit;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    final current = _value;
    if (current != null) _amount.text = _grouped.format(current);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? get _error {
    final value = _value;
    if (!_hasLimit || !_hasEdited) return null;
    if (value == null || value < minimum) return 'Set at least ${WalletFormat.money(minimum)}';
    return null;
  }

  bool get _canSave => !_hasLimit || ((_value ?? 0) >= minimum);

  void _save() {
    saveMemberPatch(
      context: context,
      group: widget.group,
      member: widget.member,
      patch: MemberPatch(
        limits: widget.member.limits.copyWith(monthlySpend: () => _hasLimit ? _value : null, overLimit: _action),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final name = member.firstName;
    return MemberSettingPage(
      title: 'Spending limit',
      group: widget.group,
      member: member,
      onSave: _save,
      canSave: _canSave,
      children: [
        SangaListGroup(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
              child: SangaToggleRow(
                leading: const SangaIconBadge(child: Icon(Icons.payments_outlined)),
                title: 'Set a monthly limit',
                subtitle: 'So $name can’t spend more than you’re comfortable with.',
                value: _hasLimit,
                onChanged: (value) => setState(() => _hasLimit = value),
              ),
            ),
            if (_hasLimit)
              Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SangaSpacing.xs,
                  children: [
                    SangaMoneyField(
                      controller: _amount,
                      hintText: 'Enter amount',
                      maxDigits: maxDigits,
                      errorText: _error,
                      onChanged: (value) => setState(() {
                        _value = value;
                        _hasEdited = true;
                      }),
                    ),
                    Text('Spent this month: ${WalletFormat.money(member.monthSpent)}', style: SangaTextStyles.caption),
                  ],
                ),
              ),
          ],
        ),
        if (_hasLimit)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.sm,
            children: [
              Text('When a ride goes over the limit', style: SangaTextStyles.label),
              for (final action in OverLimitAction.values)
                SangaOptionCard(
                  leading: SangaIconBadge(child: Icon(GroupCopy.overLimitIcon(action))),
                  title: GroupCopy.overLimitTitle(action),
                  subtitle: GroupCopy.overLimitBody(action, name),
                  isSelected: action == _action,
                  onTap: () => setState(() => _action = action),
                ),
            ],
          ),
      ],
    );
  }
}
