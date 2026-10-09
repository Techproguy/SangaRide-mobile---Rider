import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_facts.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_hero.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show RefreshMoments;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _DetailStage { loading, failed, loaded }

class WalletTransactionScreen extends StatefulWidget {
  const WalletTransactionScreen({super.key, required this.id, this.scope = const WalletScope.personal()});

  final String id;
  final WalletScope scope;

  @override
  State<WalletTransactionScreen> createState() => _WalletTransactionScreenState();
}

class _WalletTransactionScreenState extends State<WalletTransactionScreen> {
  late final _transactions = WalletControllers.transactions(widget.scope);
  StreamSubscription<void>? _resumeSubscription;

  @override
  void initState() {
    super.initState();
    _resumeSubscription = RefreshMoments.stream.listen((_) => unawaited(_transactions.refreshDetail()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_transactions.openDetail(widget.id)));
  }

  @override
  void dispose() {
    _resumeSubscription?.cancel();
    super.dispose();
  }

  _DetailStage _stageOf(TransactionDetailState state) => switch (state) {
    TransactionDetailLoading() => _DetailStage.loading,
    TransactionDetailFailed() => _DetailStage.failed,
    TransactionDetailLoaded() => _DetailStage.loaded,
  };

  void _copyReference(String reference) {
    Clipboard.setData(ClipboardData(text: reference));
    HapticFeedback.selectionClick();
    SangaToast.show('Reference copied', tone: SangaToastTone.success);
  }

  Widget? _action(WalletTransaction tx) {
    final topUpId = tx.meta.topUpId;
    if (tx.isPendingTransfer && topUpId != null) {
      return SangaButton.primary(
        label: 'Check on my transfer',
        onPressed: () => context.push(WalletRoutes.topUpTransferOf(resumeId: topUpId, groupId: widget.scope.groupId)),
      );
    }
    if (tx.kind == TransactionKind.topUp && tx.status == TransactionStatus.failed) {
      return SangaButton.primary(
        label: 'Try again',
        onPressed: () => context.push(WalletRoutes.topUpOf(amount: tx.amount, groupId: widget.scope.groupId)),
      );
    }
    return null;
  }

  List<Widget> _children(TransactionDetailState state) => switch (state) {
    TransactionDetailLoading() => [
      const SangaSkeleton.heights([150, 150]),
    ],
    TransactionDetailFailed(:final failure) when failure.canRetry => [
      SangaFailureMessage(title: failure.title, message: failure.message, onRetry: _transactions.reloadDetail),
    ],
    TransactionDetailFailed(:final failure) => [
      SangaFailureMessage(
        title: failure.title,
        message: failure.message,
        icon: Icons.search_off_rounded,
        onRetry: context.pop,
        retryLabel: 'Back to history',
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
          child: SangaRefreshList.children(onRefresh: _transactions.refreshDetail, children: _children(state)),
        );
      }),
    );
  }
}
