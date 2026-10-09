import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/balance_card.dart';
import 'package:sanga_ride/view/wallet/widgets/pending_transfer_card.dart';
import 'package:sanga_ride/view/wallet/widgets/recent_transactions.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _WalletStage { loading, failed, loaded }

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, this.scope = const WalletScope.personal()});

  final WalletScope scope;

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: WalletCopy.walletTitle(scope),
      body: WalletBody(scope: scope),
    );
  }
}

class WalletBody extends StatefulWidget {
  const WalletBody({super.key, this.scope = const WalletScope.personal(), this.canTopUp = true});

  final WalletScope scope;
  final bool canTopUp;

  @override
  State<WalletBody> createState() => _WalletBodyState();
}

class _WalletBodyState extends State<WalletBody> {
  late final _wallet = WalletControllers.wallet(widget.scope);

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

  VoidCallback? get _addMoney =>
      widget.canTopUp ? () => _push(WalletRoutes.topUpOf(groupId: widget.scope.groupId)) : null;

  List<Widget> _children(WalletState state) => switch (state) {
    WalletLoading() => [const WalletSkeleton()],
    WalletFailed() => [
      SangaInlineMessage(
        title: WalletCopy.loadFailedTitle(widget.scope),
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: _wallet.reload,
      ),
    ],
    WalletLoaded(:final overview, :final recent) => _loaded(overview, recent),
  };

  List<Widget> _loaded(WalletOverview overview, RecentTransactions recent) {
    final scope = widget.scope;
    final pending = recent is RecentLoaded ? recent.pendingTransfer : null;
    final pendingId = pending?.meta.topUpId;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.lg,
        children: [
          BalanceCard(label: WalletCopy.balanceLabel(scope), balance: overview.balance, onAddMoney: _addMoney),
          if (pending != null && pendingId != null)
            PendingTransferCard(
              transaction: pending,
              onTap: () => _push(WalletRoutes.topUpTransferOf(resumeId: pendingId, groupId: scope.groupId)),
            ),
          RecentTransactionsSection(
            recent: recent,
            scope: scope,
            onSeeAll: () => _push(WalletRoutes.transactionsOf(groupId: scope.groupId)),
            onOpen: (entry) => _push(WalletRoutes.transactionAt(entry.id, groupId: scope.groupId)),
            onRetry: _wallet.reloadQuietly,
            onAddMoney: _addMoney,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _wallet.state;
      return SangaHandoff(
        value: _stageOf(state),
        child: WalletList(onRefresh: _wallet.reloadQuietly, children: _children(state)),
      );
    });
  }
}
