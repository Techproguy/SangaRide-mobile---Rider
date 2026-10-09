import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/core/router/group_routes.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/group_invite_card.dart';
import 'package:sanga_ride/view/groups/widgets/group_start_tile.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _HubStage { loading, failed, start }

class GroupsHubScreen extends StatefulWidget {
  const GroupsHubScreen({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends State<GroupsHubScreen> {
  final _groups = Get.find<GroupsController>();
  bool _hasLeft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _openOwnGroup();
      await _groups.open();
      if (mounted) _openOwnGroup();
    });
  }

  void _openOwnGroup() {
    final group = _groups.groupOf(widget.kind);
    if (!mounted || _hasLeft || group == null || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _openGroup(group.id);
  }

  void _openGroup(String id) {
    if (_hasLeft) return;
    _hasLeft = true;
    context.pushReplacement(GroupRoutes.groupOf(id));
  }

  Future<void> _startFlow(String route) async {
    final id = await context.push<String>(route);
    if (id != null && mounted) _openGroup(id);
  }

  Future<void> _answer(GroupInvite invite, {required bool accept}) async {
    final outcome = accept ? await _groups.accept(invite) : await _groups.decline(invite);
    if (!mounted) return;
    switch (outcome) {
      case GroupDone(:final groupId) when accept && groupId != null:
        _openGroup(groupId);
      case GroupDone():
        SangaToast.show('Invite declined');
      case GroupRejected(:final failure):
        SangaToast.show(failure.message, tone: SangaToastTone.error);
    }
  }

  _HubStage _stageOf(GroupsState state) => switch (state) {
    GroupsLoading() => _HubStage.loading,
    GroupsFailed() => _HubStage.failed,
    GroupsLoaded(:final overview) when overview.groupOf(widget.kind) != null => _HubStage.loading,
    GroupsLoaded() => _HubStage.start,
  };

  List<Widget> _children(GroupsState state) => switch (_stageOf(state)) {
    _HubStage.loading => [
      const SangaSkeleton.heights([96, 96, 96]),
    ],
    _HubStage.failed => [
      SangaFailureMessage(
        title: 'We couldn’t load this',
        message: state is GroupsFailed ? state.failure.message : GroupFailure.connection.message,
        onRetry: _groups.reload,
      ),
    ],
    _HubStage.start => [_start((state as GroupsLoaded).overview)],
  };

  Widget _start(GroupsOverview overview) {
    final kind = widget.kind;
    final invites = overview.invitesOf(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        Column(
          spacing: SangaSpacing.md,
          children: [
            SangaHeroBadge(icon: GroupCopy.icon(kind)),
            Text(GroupCopy.hubLead(kind), textAlign: TextAlign.center, style: SangaTextStyles.body),
          ],
        ),
        if (invites.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.sm,
            children: [
              SangaSectionHeader(GroupCopy.invitesHeading),
              Obx(
                () => Column(
                  spacing: SangaSpacing.sm,
                  children: [
                    for (final invite in invites)
                      GroupInviteCard(
                        invite: invite,
                        isBusy: _groups.isBusy,
                        onAccept: () => _answer(invite, accept: true),
                        onDecline: () => _answer(invite, accept: false),
                      ),
                  ],
                ),
              ),
            ],
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              Expanded(
                child: GroupStartTile(
                  icon: Icons.edit_note_rounded,
                  label: GroupCopy.createTile(kind),
                  onTap: () => _startFlow(GroupRoutes.createOf(kind)),
                ),
              ),
              Expanded(
                child: GroupStartTile(
                  icon: Icons.person_add_alt_1_rounded,
                  label: GroupCopy.joinTile(kind),
                  onTap: () => _startFlow(GroupRoutes.joinOf(kind)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: GroupCopy.hubTitle(widget.kind),
      body: Obx(() {
        final state = _groups.state;
        return SangaHandoff(
          value: _stageOf(state),
          child: SangaRefreshList.children(onRefresh: _groups.reloadQuietly, children: _children(state)),
        );
      }),
    );
  }
}
