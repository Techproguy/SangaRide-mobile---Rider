import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/widgets/member_summary.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberSettingPage extends StatelessWidget {
  const MemberSettingPage({
    super.key,
    required this.title,
    required this.group,
    required this.member,
    required this.onSave,
    required this.children,
    this.canSave = true,
  });

  final String title;
  final GroupController group;
  final GroupMember member;
  final VoidCallback onSave;
  final bool canSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: title,
      footer: Obx(
        () => SangaButton.primary(label: 'Save settings', isLoading: group.isBusy, onPressed: canSave ? onSave : null),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            MemberSummary(member: member),
            const Divider(height: 1, thickness: 1, color: SangaColors.cardBorder),
            ...children,
          ],
        ),
      ],
    );
  }
}

Future<void> saveMemberPatch({
  required BuildContext context,
  required GroupController group,
  required GroupMember member,
  required MemberPatch patch,
}) async {
  final failure = await group.updateMember(member.id, patch);
  if (!context.mounted) return;
  if (failure != null) return Toast.error('${failure.title}. ${failure.message}');
  Toast.success('Saved for ${member.firstName}');
  context.pop();
}

class MemberToggleList extends StatelessWidget {
  const MemberToggleList({super.key, required this.rows});

  final List<MemberToggle> rows;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
            child: SangaToggleRow(
              leading: SangaIconBadge(child: Icon(row.icon)),
              title: row.title,
              subtitle: row.subtitle,
              value: row.value,
              onChanged: row.onChanged,
            ),
          ),
      ],
    );
  }
}

class MemberToggle {
  const MemberToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}
