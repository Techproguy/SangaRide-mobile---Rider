import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/core/services/receipt_share.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/history/history_action.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/history/widgets/history_action_row.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryActionsScreen extends StatefulWidget {
  const HistoryActionsScreen({super.key, required this.id});

  final String id;

  @override
  State<HistoryActionsScreen> createState() => _HistoryActionsScreenState();
}

class _HistoryActionsScreenState extends State<HistoryActionsScreen> {
  final _history = Get.find<RideHistoryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _history.openDetail(widget.id));
  }

  Future<void> _run(HistoryAction action, HistoryDetail detail) async {
    switch (action) {
      case HistoryAction.shareReceipt:
        await _share(detail);
      case HistoryAction.blockDriver:
        await _block(detail);
      case HistoryAction.unblockDriver:
        await _unblock(detail);
    }
  }

  Future<void> _share(HistoryDetail detail) async {
    try {
      await ReceiptShare.share(detail);
    } catch (e) {
      log('share receipt failed: $e');
      if (mounted) Toast.error('We couldn’t share your receipt. Give it another go.');
    }
  }

  Future<void> _block(HistoryDetail detail) async {
    final name = detail.driver?.profile.firstName ?? 'this driver';
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.block_rounded,
      title: 'Block $name?',
      message: 'You won’t be matched with $name again. You can unblock them from this screen anytime.',
      actionLabel: 'Block',
      dismissLabel: 'Not now',
    );
    if (!isConfirmed || !mounted) return;
    final problem = await _history.setDriverBlocked(true);
    if (!mounted) return;
    problem == null ? Toast.success('Done. You won’t be matched with $name again.') : Toast.error(problem.message);
  }

  Future<void> _unblock(HistoryDetail detail) async {
    final name = detail.driver?.profile.firstName ?? 'this driver';
    final problem = await _history.setDriverBlocked(false);
    if (!mounted) return;
    problem == null ? Toast.success('$name can be matched with you again.') : Toast.error(problem.message);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _history.detailStateFor(widget.id);
      return SangaPageLayout(
        title: 'More actions',
        children: [
          RideOptionAsyncState(
            isLoading: state is HistoryDetailLoading,
            hasFailed: state is HistoryDetailFailed,
            errorTitle: 'We couldn’t load the details',
            onRetry: _history.reloadDetail,
            skeletonCount: 2,
            skeletonHeight: 64,
            builder: (context) => switch (_history.detailStateFor(widget.id)) {
              HistoryDetailLoaded(:final detail, :final driverAction) => _actions(context, detail, driverAction),
              HistoryDetailLoading() || HistoryDetailFailed() => const SizedBox.shrink(),
            },
          ),
        ],
      );
    });
  }

  Widget _actions(BuildContext context, HistoryDetail detail, HistoryDriverAction? driverAction) {
    final actions = HistoryAction.availableFor(detail);
    if (actions.isEmpty) {
      return SangaInlineMessage(
        title: 'Nothing to do here',
        message: 'There are no actions for this trip.',
        actionLabel: 'Go back',
        onAction: context.pop,
      );
    }
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final action in actions)
          HistoryActionRow(
            action: action,
            isBusy: driverAction != null && action != HistoryAction.shareReceipt,
            onTap: () => _run(action, detail),
          ),
      ],
    );
  }
}
