import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/core/services/receipt_share.dart';
import 'package:sanga_ride/model/history/history_action.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/history/widgets/history_action_row.dart';
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
    } on Object {
      if (mounted) SangaToast.show('We couldn’t share your receipt. Give it another go.', tone: SangaToastTone.error);
    }
  }

  Future<void> _block(HistoryDetail detail) async {
    final name = detail.driver?.profile.firstName ?? 'this driver';
    final isConfirmed = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      icon: Icons.block_rounded,
      title: 'Block $name?',
      message: 'You won’t be matched with $name again. You can unblock them from this screen anytime.',
      actionLabel: 'Block',
      secondaryLabel: 'Not now',
      isDestructive: true,
    );
    if (!isConfirmed || !mounted) return;
    final problem = await _history.setDriverBlocked(true);
    if (!mounted) return;
    SangaToast.show(
      problem == null ? 'Done. You won’t be matched with $name again.' : problem.message,
      tone: problem == null ? SangaToastTone.success : SangaToastTone.error,
    );
  }

  Future<void> _unblock(HistoryDetail detail) async {
    final name = detail.driver?.profile.firstName ?? 'this driver';
    final problem = await _history.setDriverBlocked(false);
    if (!mounted) return;
    SangaToast.show(
      problem == null ? '$name can be matched with you again.' : problem.message,
      tone: problem == null ? SangaToastTone.success : SangaToastTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _history.detailStateFor(widget.id);
      return SangaPageLayout(
        title: 'More actions',
        children: [
          switch (state) {
            HistoryDetailLoading() => const SangaSkeleton.list(count: 2, height: 64),
            HistoryDetailFailed(:final reason) when reason.canRetry => SangaFailureMessage(
              title: reason.title,
              message: reason.message,
              onRetry: _history.reloadDetail,
            ),
            HistoryDetailFailed(:final reason) => SangaFailureMessage(
              title: reason.title,
              message: reason.message,
              icon: Icons.search_off_rounded,
              retryLabel: 'Go back',
              onRetry: context.pop,
            ),
            HistoryDetailLoaded(:final detail, :final driverAction) => _actions(context, detail, driverAction),
          },
        ],
      );
    });
  }

  Widget _actions(BuildContext context, HistoryDetail detail, HistoryDriverAction? driverAction) {
    final actions = HistoryAction.availableFor(detail);
    if (actions.isEmpty) {
      return SangaEmptyMessage(
        icon: Icons.check_circle_outline_rounded,
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
