import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/invite_code_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final _groups = Get.find<GroupsController>();
  final _code = TextEditingController();
  GroupFailure? _failure;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    final outcome = await _groups.join(InviteCode.clean(_code.text));
    if (!mounted) return;
    switch (outcome) {
      case GroupDone(:final groupId):
        context.pop(groupId);
      case GroupRejected(:final failure)
          when failure == GroupFailure.connection ||
              failure == GroupFailure.unknown ||
              failure == GroupFailure.unconfirmed:
        SangaToast.show('${failure.title}. ${failure.message}', tone: SangaToastTone.error);
      case GroupRejected(:final failure):
        setState(() => _failure = failure);
    }
  }

  void _onChanged(String _) {
    setState(() => _failure = null);
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return SangaPageLayout(
      title: GroupCopy.joinTile(widget.kind),
      footer: ListenableBuilder(
        listenable: _code,
        builder: (context, _) => Obx(
          () => SangaButton.primary(
            label: 'Join',
            isLoading: _groups.isBusy,
            onPressed: InviteCode.isComplete(_code.text) ? _join : null,
          ),
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            Text(GroupCopy.joinLead(widget.kind), style: SangaTextStyles.body),
            SangaTextField(
              label: 'Invite code',
              isRequired: true,
              hintText: 'XXXX-XXXX',
              controller: _code,
              errorText: failure == null ? null : '${failure.title}. ${failure.message}',
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: const [InviteCodeFormatter()],
              onChanged: _onChanged,
              onSubmitted: (_) {
                if (InviteCode.isComplete(_code.text)) _join();
              },
            ),
          ],
        ),
      ],
    );
  }
}
