import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/approval_card.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show RefreshMoments;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _ApprovalsStage { loading, failed, unavailable, empty, list }

class GroupApprovalsScreen extends StatefulWidget {
  const GroupApprovalsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupApprovalsScreen> createState() => _GroupApprovalsScreenState();
}

class _GroupApprovalsScreenState extends State<GroupApprovalsScreen> {
  late final GroupController _group = GroupControllers.group(widget.groupId);
  StreamSubscription<void>? _resumeSubscription;

  @override
  void initState() {
    super.initState();
    _resumeSubscription = RefreshMoments.stream.listen((_) => unawaited(_group.loadApprovals()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_group.loadApprovals()));
  }

  @override
  void dispose() {
    _resumeSubscription?.cancel();
    super.dispose();
  }

  _ApprovalsStage _stageOf(ApprovalsState state) => switch (state) {
    ApprovalsLoading() => _ApprovalsStage.loading,
    ApprovalsFailed() => _ApprovalsStage.failed,
    ApprovalsUnavailable() => _ApprovalsStage.unavailable,
    ApprovalsLoaded(:final approvals) when approvals.isEmpty => _ApprovalsStage.empty,
    ApprovalsLoaded() => _ApprovalsStage.list,
  };

  Future<void> _decide(GroupApproval approval, {required bool approve}) async {
    final failure = await _group.decide(approval, approve: approve);
    if (!mounted) return;
    if (failure == null) {
      SangaToast.show(GroupCopy.approvalDecided(approval.firstName, approved: approve), tone: SangaToastTone.success);
    } else {
      SangaToast.show(
        GroupCopy.failureText(failure),
        tone: failure.closesApproval ? SangaToastTone.warning : SangaToastTone.error,
      );
    }
  }

  List<Widget> _children(ApprovalsState state) => switch (state) {
    ApprovalsLoading() => [
      const SangaSkeleton.heights([150, 150]),
    ],
    ApprovalsFailed(:final failure) => [
      SangaFailureMessage(
        title: GroupCopy.requestsLoadFailed,
        message: failure.message,
        onRetry: _group.retryApprovals,
      ),
    ],
    ApprovalsUnavailable() => [
      SangaEmptyMessage(
        icon: Icons.lock_outline_rounded,
        title: GroupCopy.requestsUnavailableTitle,
        message: GroupCopy.requestsUnavailableMessage,
        actionLabel: GroupCopy.back,
        onAction: context.pop,
      ),
    ],
    ApprovalsLoaded(:final approvals) when approvals.isEmpty => [
      const SangaEmptyMessage(
        icon: Icons.check_circle_outline_rounded,
        title: GroupCopy.allCaughtUp,
        message: GroupCopy.allCaughtUpMessage,
      ),
    ],
    ApprovalsLoaded(:final approvals, :final deciding, :final isStale) => [
      Column(
        spacing: SangaSpacing.md,
        children: [
          if (isStale) SangaStaleNotice(onRetry: _group.loadApprovals),
          for (final approval in approvals)
            ApprovalCard(
              approval: approval,
              isDeciding: deciding == approval.id,
              isLocked: deciding != null,
              onApprove: () => _decide(approval, approve: true),
              onDecline: () => _decide(approval, approve: false),
              onExpired: () => unawaited(_group.loadApprovals()),
            ),
        ],
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: GroupCopy.rideRequests,
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
