import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride/view/groups/widgets/invite_code_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupInviteScreen extends StatelessWidget {
  const GroupInviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return GroupGate(
      groupId: groupId,
      title: GroupCopy.inviteSomeone,
      builder: (context, group, detail) => _InviteForm(group: group, detail: detail),
    );
  }
}

class _InviteForm extends StatefulWidget {
  const _InviteForm({required this.group, required this.detail});

  final GroupController group;
  final GroupDetail detail;

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  final _phone = TextEditingController();
  late String _relation = GroupCopy.relations(widget.detail.kind).first;
  bool _asAdmin = false;
  String? _phoneError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!SangaPhoneNumber.isValid(_phone.text)) {
      return setState(() => _phoneError = CommonCopy.invalidPhone);
    }
    final outcome = await widget.group.invite(
      phone: SangaPhoneNumber.toE164(_phone.text),
      relation: _relation,
      role: _asAdmin ? GroupRole.admin : GroupRole.member,
    );
    if (!mounted) return;
    switch (outcome) {
      case GroupDone():
        SangaToast.show(GroupCopy.inviteSent(SangaPhoneNumber.masked(_phone.text)), tone: SangaToastTone.success);
        context.pop();
      case GroupRejected(:final failure)
          when failure == GroupFailure.invalidPhone || failure == GroupFailure.phoneInGroup:
        setState(() => _phoneError = GroupCopy.failureText(failure));
      case GroupRejected(:final failure):
        SangaToast.show(GroupCopy.failureText(failure), tone: SangaToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return SangaPageLayout(
      title: GroupCopy.inviteTitle(detail.kind),
      footer: Obx(
        () => SangaButton.primary(label: GroupCopy.sendInvite, isLoading: widget.group.isBusy, onPressed: _send),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            Text(GroupCopy.inviteLead(detail.kind), style: SangaTextStyles.body),
            SangaPhoneField(
              controller: _phone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
              onSubmitted: (_) => _send(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xs,
              children: [
                const SangaSectionHeader(GroupCopy.whoAreTheyToYou),
                SangaChoiceChips<String>(
                  options: [
                    for (final relation in GroupCopy.relations(detail.kind)) SangaSelectOption(relation, relation),
                  ],
                  value: _relation,
                  onChanged: (relation) => setState(() => _relation = relation),
                ),
              ],
            ),
            SangaListGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
                  child: SangaToggleRow(
                    leading: const SangaIconBadge(child: Icon(Icons.shield_outlined)),
                    title: GroupCopy.makeThemAdmin,
                    subtitle: GroupCopy.adminCan,
                    value: _asAdmin,
                    onChanged: (value) => setState(() => _asAdmin = value),
                  ),
                ),
              ],
            ),
            InviteCodeCard(
              kind: detail.kind,
              groupName: detail.name,
              code: detail.inviteCode,
              onCopied: () {
                Clipboard.setData(ClipboardData(text: detail.inviteCode));
                HapticFeedback.selectionClick();
                SangaToast.show(GroupCopy.codeCopied, tone: SangaToastTone.success);
              },
            ),
          ],
        ),
      ],
    );
  }
}
