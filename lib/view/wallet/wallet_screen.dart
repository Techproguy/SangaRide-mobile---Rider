import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/balance_card.dart';
import 'package:sanga_ride/view/wallet/widgets/pending_transfer_card.dart';
import 'package:sanga_ride/view/wallet/widgets/recent_transactions.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _WalletStage { loading, failed, loaded }

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _wallet = Get.find<WalletController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_wallet.open()));
  }

  _WalletStage _stageOf(WalletState state) => switch (state) {
    WalletLoading() => _WalletStage.loading,
    WalletFailed() => _WalletStage.failed,
    WalletLoaded() => _WalletStage.loaded,
  };

  Future<void> _push(String location) async {
    await context.push<Object?>(location);
    if (mounted) unawaited(_wallet.reloadQuietly());
  }

  List<Widget> _children(WalletState state) => switch (state) {
    WalletLoading() => [const WalletSkeleton()],
    WalletFailed() => [
      SangaInlineMessage(
        title: 'We couldn’t load your wallet',
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: _wallet.reload,
      ),
    ],
    WalletLoaded(:final overview, :final recent) => _loaded(overview, recent),
  };

  List<Widget> _loaded(WalletOverview overview, RecentTransactions recent) {
    final pending = recent is RecentLoaded ? recent.pendingTransfer : null;
    final pendingId = pending?.meta.topUpId;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.lg,
        children: [
          BalanceCard(balance: overview.balance, onAddMoney: () => _push(WalletRoutes.topUp)),
          if (pending != null && pendingId != null)
            PendingTransferCard(
              transaction: pending,
              onTap: () => _push(WalletRoutes.topUpTransferOf(resumeId: pendingId)),
            ),
          RecentTransactionsSection(
            recent: recent,
            onSeeAll: () => _push(WalletRoutes.transactions),
            onOpen: (entry) => _push(WalletRoutes.transactionOf(entry.id)),
            onRetry: _wallet.reloadQuietly,
            onAddMoney: () => _push(WalletRoutes.topUp),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: 'Wallet',
      body: Obx(() {
        final state = _wallet.state;
        return SangaHandoff(
          value: _stageOf(state),
          child: WalletList(onRefresh: _wallet.reloadQuietly, children: _children(state)),
        );
      }),
    );
  }
}
