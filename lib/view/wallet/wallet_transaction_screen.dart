import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_transactions_controller.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_facts.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_hero.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _DetailStage { loading, failed, loaded }

class WalletTransactionScreen extends StatefulWidget {
  const WalletTransactionScreen({super.key, required this.id});

  final String id;

  @override
  State<WalletTransactionScreen> createState() => _WalletTransactionScreenState();
}

class _WalletTransactionScreenState extends State<WalletTransactionScreen> {
  final _transactions = Get.find<WalletTransactionsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_transactions.openDetail(widget.id)));
  }

  _DetailStage _stageOf(TransactionDetailState state) => switch (state) {
    TransactionDetailLoading() => _DetailStage.loading,
    TransactionDetailFailed() => _DetailStage.failed,
    TransactionDetailLoaded() => _DetailStage.loaded,
  };

  void _copyReference(String reference) {
    Clipboard.setData(ClipboardData(text: reference));
    HapticFeedback.selectionClick();
    Toast.success('Reference copied');
  }

  Widget? _action(WalletTransaction tx) {
    final topUpId = tx.meta.topUpId;
    if (tx.isPendingTransfer && topUpId != null) {
      return SangaButton.primary(
        label: 'Check on my transfer',
        onPressed: () => context.push(WalletRoutes.topUpTransferOf(resumeId: topUpId)),
      );
    }
    if (tx.kind == TransactionKind.topUp && tx.status == TransactionStatus.failed) {
      return SangaButton.primary(
        label: 'Try again',
        onPressed: () => context.push(WalletRoutes.topUpOf(amount: tx.amount)),
      );
    }
    return null;
  }

  List<Widget> _children(TransactionDetailState state) => switch (state) {
    TransactionDetailLoading() => [
      const WalletSkeleton(heights: [150, 150]),
    ],
    TransactionDetailFailed(:final failure) when failure.canRetry => [
      SangaInlineMessage(
        title: failure.title,
        message: failure.message,
        actionLabel: 'Try again',
        onAction: _transactions.reloadDetail,
      ),
    ],
    TransactionDetailFailed(:final failure) => [
      SangaInlineMessage(
        title: failure.title,
        message: failure.message,
        actionLabel: 'Back to history',
        onAction: context.pop,
      ),
    ],
    TransactionDetailLoaded(:final transaction) => _loaded(transaction),
  };

  List<Widget> _loaded(WalletTransaction tx) {
    final tripId = tx.meta.tripId;
    final action = _action(tx);
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: [
          TransactionHero(transaction: tx),
          ...TransactionFacts.sections(tx),
          if (tripId != null)
            SangaListGroup(
              children: [
                SangaListRow(
                  leading: const SangaIconBadge(size: 40, child: Icon(Icons.route_rounded)),
                  title: 'View ride details',
                  subtitle: tx.meta.route,
                  onTap: () => context.push(HistoryRoutes.detailOf(tripId)),
                ),
              ],
            ),
          ?action,
          TextButton(
            onPressed: () => _copyReference(tx.reference),
            child: Text(
              'Copy reference · ${tx.reference}',
              style: SangaTextStyles.label.copyWith(color: SangaColors.primary),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: 'Transaction',
      body: Obx(() {
        final state = _transactions.detailFor(widget.id);
        return SangaHandoff(
          value: _stageOf(state),
          child: WalletList(onRefresh: _transactions.refreshDetail, children: _children(state)),
        );
      }),
    );
  }
}
