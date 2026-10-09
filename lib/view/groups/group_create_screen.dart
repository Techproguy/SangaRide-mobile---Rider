import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  static const int nameLimit = 40;
  static const int rcLimit = 20;
  static const int addressLimit = 120;

  final _groups = Get.find<GroupsController>();
  final _name = TextEditingController();
  final _rcNumber = TextEditingController();
  final _address = TextEditingController();
  late CreatorRole _role = CreatorRole.of(widget.kind).first;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _rcNumber.dispose();
    _address.dispose();
    super.dispose();
  }

  GroupCompany? get _company {
    if (widget.kind != GroupKind.business) return null;
    final rc = _rcNumber.text.trim();
    final address = _address.text.trim();
    final company = GroupCompany(rcNumber: rc.isEmpty ? null : rc, address: address.isEmpty ? null : address);
    return company.isEmpty ? null : company;
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty) return setState(() => _nameError = GroupFailure.nameRequired.message);
    final outcome = await _groups.create(kind: widget.kind, name: _name.text, role: _role.code, company: _company);
    if (!mounted) return;
    switch (outcome) {
      case GroupDone(:final groupId):
        context.pop(groupId);
      case GroupRejected(:final failure) when failure == GroupFailure.nameRequired:
        setState(() => _nameError = failure.message);
      case GroupRejected(:final failure):
        Toast.error('${failure.title}. ${failure.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return SangaPageLayout(
      title: GroupCopy.createTile(kind),
      footer: Obx(() => SangaButton.primary(label: 'Confirm', isLoading: _groups.isBusy, onPressed: _confirm)),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            SangaTextField(
              label: GroupCopy.nameLabel(kind),
              isRequired: true,
              hintText: GroupCopy.nameHint(kind),
              controller: _name,
              errorText: _nameError,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(nameLimit)],
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            if (kind == GroupKind.business) ...[
              SangaTextField(
                label: 'RC number',
                hintText: 'Optional',
                controller: _rcNumber,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(rcLimit)],
              ),
              SangaTextField(
                label: 'Company address',
                hintText: 'Optional',
                controller: _address,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(addressLimit)],
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.sm,
              children: [
                Text(GroupCopy.roleTitle(kind), style: SangaTextStyles.label),
                for (final role in CreatorRole.of(kind))
                  SangaOptionCard(
                    leading: SangaIconBadge(child: Icon(_iconOf(role))),
                    title: role.label,
                    subtitle: role.description,
                    isSelected: role == _role,
                    onTap: () => setState(() => _role = role),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  IconData _iconOf(CreatorRole role) => switch (role) {
    CreatorRole.parent => Icons.supervisor_account_rounded,
    CreatorRole.guardian => Icons.shield_outlined,
    CreatorRole.spouse => Icons.favorite_border_rounded,
    CreatorRole.owner => Icons.workspace_premium_outlined,
    CreatorRole.manager => Icons.badge_outlined,
    CreatorRole.familyOther || CreatorRole.businessOther => Icons.person_outline_rounded,
  };
}
