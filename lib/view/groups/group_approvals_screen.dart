import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/widgets/approval_card.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _ApprovalsStage { loading, failed, empty, list }

class GroupApprovalsScreen extends StatefulWidget {
  const GroupApprovalsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupApprovalsScreen> createState() => _GroupApprovalsScreenState();
}

class _GroupApprovalsScreenState extends State<GroupApprovalsScreen> {
  late final GroupController _group = GroupControllers.group(widget.groupId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_group.loadApprovals()));
  }

  _ApprovalsStage _stageOf(ApprovalsState state) => switch (state) {
    ApprovalsLoading() => _ApprovalsStage.loading,
    ApprovalsFailed() => _ApprovalsStage.failed,
    ApprovalsLoaded(:final approvals) when approvals.isEmpty => _ApprovalsStage.empty,
    ApprovalsLoaded() => _ApprovalsStage.list,
  };

  Future<void> _decide(GroupApproval approval, {required bool approve}) async {
    final failure = await _group.decide(approval, approve: approve);
    if (!mounted) return;
    if (failure == null) {
      Toast.success(approve ? '${approval.firstName}’s ride is approved' : '${approval.firstName}’s ride was declined');
    } else {
      Toast.error('${failure.title}. ${failure.message}');
    }
  }

  List<Widget> _children(ApprovalsState state) => switch (state) {
    ApprovalsLoading() => [
      const SangaSkeleton.heights([150, 150]),
    ],
    ApprovalsFailed() => [
      SangaInlineMessage(
        title: 'We couldn’t load the requests',
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: _group.retryApprovals,
      ),
    ],
    ApprovalsLoaded(:final approvals) when approvals.isEmpty => [
      const SangaInlineMessage(
        title: 'All caught up',
        message: 'When a ride goes past someone’s limit, it lands here for your OK.',
      ),
    ],
    ApprovalsLoaded(:final approvals, :final deciding) => [
      Column(
        spacing: SangaSpacing.md,
        children: [
          for (final approval in approvals)
            ApprovalCard(
              approval: approval,
              isDeciding: deciding == approval.id,
              isLocked: deciding != null,
              onApprove: () => _decide(approval, approve: true),
              onDecline: () => _decide(approval, approve: false),
            ),
        ],
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: 'Ride requests',
      body: Obx(() {
        final state = _group.approvalsState;
        return SangaHandoff(
          value: _stageOf(state),
          child: SangaRefreshList.children(onRefresh: _group.loadApprovals, children: _children(state)),
        );
      }),
    );
  }
}
