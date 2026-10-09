import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/group_approvals_banner.dart';
import 'package:sanga_ride/view/groups/widgets/group_header_card.dart';
import 'package:sanga_ride/view/groups/widgets/group_members_tab.dart';
import 'package:sanga_ride/view/groups/widgets/group_rides_tab.dart';
import 'package:sanga_ride/view/history/widgets/history_tab_bar.dart';
import 'package:sanga_ride/view/wallet/wallet_screen.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum GroupTab {
  members('Members'),
  wallet('Wallet'),
  rides('Rides');

  const GroupTab(this.label);

  final String label;
}

enum _GroupStage { loading, failed, loaded }

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.groupId, this.initialTab = GroupTab.members});

  final String groupId;
  final GroupTab initialTab;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> with SingleTickerProviderStateMixin {
  late final GroupController _group = GroupControllers.group(widget.groupId);
  late final TabController _tabs = TabController(
    length: GroupTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_group.open()));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  _GroupStage _stageOf(GroupDetailState state) => switch (state) {
    GroupDetailLoading() => _GroupStage.loading,
    GroupDetailFailed() => _GroupStage.failed,
    GroupDetailLoaded() => _GroupStage.loaded,
  };

  Future<void> _push(String route) async {
    await context.push<Object?>(route);
    if (mounted) unawaited(_group.reloadQuietly());
  }

  Future<void> _leave(GroupDetail detail) async {
    final confirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.door_back_door_outlined,
      title: GroupCopy.leaveTitle(detail.kind),
      message: GroupCopy.leaveMessage(detail.name),
      actionLabel: 'Leave',
      dismissLabel: 'Stay',
    );
    if (!confirmed || !mounted) return;
    final failure = await _group.leave();
    if (!mounted) return;
    if (failure != null) return Toast.error('${failure.title}. ${failure.message}');
    Toast.success('You left ${detail.name}');
    context.pop();
  }

  Widget _tab(GroupTab tab, GroupDetail detail) => switch (tab) {
    GroupTab.members => GroupMembersTab(
      detail: detail,
      myId: _group.me?.id,
      canManageMember: _group.canManageMember,
      onRefresh: _group.reloadQuietly,
      onInvite: () => _push(GroupRoutes.inviteOf(detail.id)),
      onOpenMember: (member) => _push(GroupRoutes.memberOf(detail.id, member.id)),
      onLeave: () => _leave(detail),
    ),
    GroupTab.wallet => WalletBody(scope: WalletScope.group(detail.id), canTopUp: detail.canManage),
    GroupTab.rides => GroupRidesTab(detail: detail),
  };

  Widget _header(GroupDetail detail) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, SangaSpacing.sm),
      child: Column(
        spacing: SangaSpacing.sm,
        children: [
          GroupHeaderCard(detail: detail),
          Obx(() {
            final state = _group.approvalsState;
            if (state is! ApprovalsLoaded || state.approvals.isEmpty) return const SizedBox.shrink();
            return GroupApprovalsBanner(
              approvals: state.approvals,
              onTap: () => _push(GroupRoutes.approvalsOf(detail.id)),
            );
          }),
        ],
      ),
    );
  }

  Widget _tabBar() => HistoryTabBar(controller: _tabs, labels: [for (final tab in GroupTab.values) tab.label]);

  Widget _body(GroupDetailState state) => switch (state) {
    GroupDetailLoading() => const _GroupSkeleton(),
    GroupDetailFailed(:final failure) => WalletList(
      onRefresh: _group.reload,
      children: [
        SangaInlineMessage(
          title: failure.title,
          message: failure.message,
          actionLabel: failure.isNotFound ? 'Back' : 'Try again',
          onAction: failure.isNotFound ? context.pop : _group.reload,
        ),
      ],
    ),
    GroupDetailLoaded(:final detail) => ListenableBuilder(
      listenable: _tabs,
      builder: (context, _) {
        final tab = GroupTab.values[_tabs.index];
        return SangaHandoff(value: tab, child: _tab(tab, detail));
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _group.state;
      final detail = state is GroupDetailLoaded ? state.detail : null;
      return WalletPage(
        title: detail == null ? 'Family and business' : GroupCopy.label(detail.kind),
        tabs: detail == null ? null : Column(children: [_header(detail), _tabBar()]),
        body: SangaHandoff(value: _stageOf(state), child: _body(state)),
      );
    });
  }
}

class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

  @override
  Widget build(BuildContext context) {
    return const WalletList(
      onRefresh: _noop,
      children: [
        WalletSkeleton(heights: [72, 56, 56, 56]),
      ],
    );
  }

  static Future<void> _noop() async {}
}
