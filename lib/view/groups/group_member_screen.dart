import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride/view/groups/widgets/member_summary.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupMemberScreen extends StatelessWidget {
  const GroupMemberScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: 'Manage member',
      builder: (context, group, detail, member) => _MemberMenu(group: group, detail: detail, member: member),
    );
  }
}

class _MemberMenu extends StatelessWidget {
  const _MemberMenu({required this.group, required this.detail, required this.member});

  final GroupController group;
  final GroupDetail detail;
  final GroupMember member;

  bool get _isManager => member.role.canManage;

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return SangaListRow(
      leading: SangaIconBadge(size: 36, child: Icon(icon)),
      title: title,
      subtitle: subtitle,
      onTap: () => context.push(route),
    );
  }

  Widget _relationRow(BuildContext context) => _row(
    context,
    icon: Icons.favorite_border_rounded,
    title: 'Relation',
    subtitle: member.relation,
    route: GroupRoutes.relationOf(detail.id, member.id),
  );

  List<Widget> _settings(BuildContext context) {
    final limits = member.limits;
    final localizations = MaterialLocalizations.of(context);
    String route(String Function(String, String) of) => of(detail.id, member.id);
    return [
      _row(
        context,
        icon: Icons.tune_rounded,
        title: 'Permissions',
        subtitle: GroupCopy.permissionsSummary(member.permissions),
        route: route(GroupRoutes.permissionsOf),
      ),
      _row(
        context,
        icon: Icons.payments_outlined,
        title: 'Spending limit',
        subtitle: GroupCopy.spendSummary(limits),
        route: route(GroupRoutes.spendingOf),
      ),
      _row(
        context,
        icon: Icons.directions_car_filled_outlined,
        title: 'Ride limit',
        subtitle: GroupCopy.ridesSummary(limits),
        route: route(GroupRoutes.rideLimitOf),
      ),
      _row(
        context,
        icon: Icons.location_on_outlined,
        title: 'Approved places',
        subtitle: GroupCopy.placesSummary(limits),
        route: route(GroupRoutes.placesOf),
      ),
      _row(
        context,
        icon: Icons.schedule_rounded,
        title: 'Time window',
        subtitle: GroupCopy.timeSummary(limits, localizations),
        route: route(GroupRoutes.timeOf),
      ),
      _row(
        context,
        icon: Icons.local_taxi_outlined,
        title: 'Ride types',
        subtitle: GroupCopy.typesSummary(limits),
        route: route(GroupRoutes.rideTypesOf),
      ),
      _row(
        context,
        icon: Icons.notifications_none_rounded,
        title: 'Alerts',
        subtitle: GroupCopy.alertsSummary(member.alerts),
        route: route(GroupRoutes.alertsOf),
      ),
      _relationRow(context),
    ];
  }

  Future<void> _changeRole(BuildContext context) async {
    final promote = !_isManager;
    final confirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.shield_outlined,
      title: promote ? GroupCopy.adminPrompt(member) : GroupCopy.demotePrompt(member),
      message: promote ? GroupCopy.adminMessage(member, detail.name) : GroupCopy.demoteMessage(member),
      actionLabel: promote ? 'Make admin' : 'Make member',
    );
    if (!confirmed || !context.mounted) return;
    final failure = await group.updateMember(
      member.id,
      MemberPatch(role: promote ? GroupRole.admin : GroupRole.member),
    );
    if (!context.mounted) return;
    if (failure != null) {
      SangaToast.show('${failure.title}. ${failure.message}', tone: SangaToastTone.error);
      return;
    }
    SangaToast.show(
      promote ? '${member.firstName} is now an admin' : '${member.firstName} is now a member',
      tone: SangaToastTone.success,
    );
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      icon: Icons.person_remove_outlined,
      title: GroupCopy.removePrompt(member),
      message: GroupCopy.removeMessage(member, detail.name),
      actionLabel: GroupCopy.removeAction(member),
      secondaryLabel: 'Keep',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final failure = await group.removeMember(member.id);
    if (!context.mounted) return;
    if (failure != null && failure != GroupFailure.memberNotFound) {
      SangaToast.show('${failure.title}. ${failure.message}', tone: SangaToastTone.error);
      return;
    }
    SangaToast.show(
      member.isInvited ? 'Invite cancelled' : '${member.firstName} was removed',
      tone: SangaToastTone.success,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canChangeRole = !member.isInvited && (!_isManager || detail.role == GroupRole.owner);
    return SangaPageLayout(
      title: 'Manage member',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            MemberSummary(member: member),
            if (!_isManager) SangaListGroup(children: _settings(context)),
            SangaListGroup(
              children: [
                if (canChangeRole)
                  SangaListRow(
                    leading: SangaIconBadge(
                      size: 36,
                      child: Icon(_isManager ? Icons.person_outline_rounded : Icons.shield_outlined),
                    ),
                    title: _isManager ? 'Make member' : 'Make admin',
                    subtitle: _isManager
                        ? 'They stay in, without managing the group.'
                        : 'They can manage the group with you.',
                    onTap: () => _changeRole(context),
                  ),
                SangaListRow(
                  leading: const _DangerBadge(),
                  title: GroupCopy.removeTitle(member),
                  onTap: () => _remove(context),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DangerBadge extends StatelessWidget {
  const _DangerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SangaColors.dangerSoft,
        borderRadius: SangaRadii.digit,
        border: Border.all(color: SangaColors.dangerStrong, width: 0.5),
      ),
      child: const Icon(Icons.person_remove_outlined, size: 20, color: SangaColors.dangerStrong),
    );
  }
}
