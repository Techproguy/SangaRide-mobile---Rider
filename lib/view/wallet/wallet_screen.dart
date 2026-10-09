import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/widgets/balance_card.dart';
import 'package:sanga_ride/view/wallet/widgets/pending_transfer_card.dart';
import 'package:sanga_ride/view/wallet/widgets/recent_transactions.dart';
import 'package:sanga_ride/view/wallet/widgets/resume_top_up_card.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show RefreshMoments;
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
  late final _topUp = WalletControllers.topUp(widget.scope);
  StreamSubscription<void>? _resumeSubscription;

  @override
  void initState() {
    super.initState();
    _resumeSubscription = RefreshMoments.stream.listen((_) => unawaited(_refresh()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _resumeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    await _wallet.open();
    if (!mounted) return;
    await _topUp.reviveSaved();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await _reloadAll();
  }

  Future<void> _openSaved(SavedTopUp saved) async {
    final id = saved.topUpId;
    if (id == null) return;
    if (saved.method == TopUpMethod.transfer) {
      return _push(WalletRoutes.topUpTransferOf(resumeId: id, groupId: widget.scope.groupId));
    }
    await _topUp.resume(saved);
    if (!mounted) return;
    await _push(WalletRoutes.topUpCardOf(groupId: widget.scope.groupId));
  }

  Future<void> _reloadAll() async {
    await _wallet.reloadQuietly();
    if (mounted) await _topUp.reviveSaved();
  }

  _WalletStage _stageOf(WalletState state) => switch (state) {
    WalletLoading() => _WalletStage.loading,
    WalletFailed() => _WalletStage.failed,
    WalletLoaded() => _WalletStage.loaded,
  };

  Future<void> _push(String location) async {
    await context.push<Object?>(location);
    if (mounted) unawaited(_reloadAll());
  }

  VoidCallback? get _addMoney =>
      widget.canTopUp ? () => _push(WalletRoutes.topUpOf(groupId: widget.scope.groupId)) : null;

  List<Widget> _children(WalletState state, SavedTopUp? saved) => switch (state) {
    WalletLoading() => [
      const SangaSkeleton.heights([112, 56, 56, 56]),
    ],
    WalletFailed(:final problem) => [
      SangaFailureMessage(
        title: WalletCopy.loadFailedTitle(widget.scope),
        message: problem.message,
        onRetry: _wallet.reload,
      ),
    ],
    WalletLoaded(:final overview, :final recent, :final isStale) => _loaded(overview, recent, isStale, saved),
  };

  List<Widget> _loaded(WalletOverview overview, RecentTransactions recent, bool isStale, SavedTopUp? saved) {
    final scope = widget.scope;
    final pending = recent is RecentLoaded ? recent.pendingTransfer : null;
    final pendingId = pending?.meta.topUpId;
    final showsSaved = saved != null && (pending == null || saved.topUpId != pendingId);
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.lg,
        children: [
          if (isStale) SangaStaleNotice(onRetry: _wallet.reloadQuietly),
          BalanceCard(label: WalletCopy.balanceLabel(scope), balance: overview.balance, onAddMoney: _addMoney),
          if (showsSaved && widget.canTopUp) ResumeTopUpCard(saved: saved, onTap: () => _openSaved(saved)),
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
      final saved = _topUp.saved;
      return SangaHandoff(
        value: _stageOf(state),
        child: SangaRefreshList.children(onRefresh: _reloadAll, children: _children(state, saved)),
      );
    });
  }
}
