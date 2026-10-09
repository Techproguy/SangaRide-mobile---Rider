import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_filter_chips.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_row.dart';
import 'package:sanga_ride/view/wallet/widgets/wallet_page.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _FeedStage { loading, failed, empty, list }

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key, this.scope = const WalletScope.personal()});

  final WalletScope scope;

  @override
  State<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  static const double _loadMoreExtent = 240;

  late final _transactions = WalletControllers.transactions(widget.scope);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_transactions.open()));
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadMoreExtent) unawaited(_transactions.loadMore());
    return false;
  }

  _FeedStage _stageOf(TransactionFeed feed) => switch (feed) {
    TransactionsLoading() => _FeedStage.loading,
    TransactionsFailed() => _FeedStage.failed,
    TransactionsLoaded(:final entries) when entries.isEmpty => _FeedStage.empty,
    TransactionsLoaded() => _FeedStage.list,
  };

  Widget _footer(TransactionsLoaded feed) => switch (feed.more) {
    TransactionMore.loading => const Padding(
      padding: EdgeInsets.all(SangaSpacing.md),
      child: Center(child: SangaActivityIndicator(size: 24)),
    ),
    TransactionMore.failed => SangaInlineMessage(
      title: 'We couldn’t load more',
      message: 'Check your connection and give it another go.',
      actionLabel: 'Try again',
      onAction: _transactions.loadMore,
    ),
    TransactionMore.idle => const SizedBox.shrink(),
  };

  List<Widget> _children(TransactionFeed feed) => switch (feed) {
    TransactionsLoading() => [
      const WalletSkeleton(heights: [56, 56, 56, 56, 56]),
    ],
    TransactionsFailed() => [
      SangaInlineMessage(
        title: WalletCopy.historyFailedTitle(widget.scope),
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: _transactions.retry,
      ),
    ],
    TransactionsLoaded(:final entries) when entries.isEmpty => [
      SangaInlineMessage(
        title: WalletCopy.emptyTransactionsTitle(_transactions.filter),
        message: WalletCopy.emptyTransactionsMessage(_transactions.filter),
      ),
    ],
    final TransactionsLoaded loaded => [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: [
          for (final day in TransactionDay.group(loaded.entries))
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.sm,
              children: [
                SangaSectionHeader(WalletFormat.dayHeading(day.date)),
                SangaListGroup(
                  children: [
                    for (final entry in day.entries)
                      TransactionRow(
                        transaction: entry,
                        onTap: () => context.push(WalletRoutes.transactionAt(entry.id, groupId: widget.scope.groupId)),
                      ),
                  ],
                ),
              ],
            ),
          _footer(loaded),
        ],
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: WalletCopy.transactionsTitle(widget.scope),
      tabs: Obx(() => TransactionFilterChips(selected: _transactions.filter, onSelected: _transactions.select)),
      body: Obx(() {
        final feed = _transactions.feed;
        return SangaHandoff(
          value: (_transactions.filter, _stageOf(feed)),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: WalletList(onRefresh: _transactions.refreshFeed, children: _children(feed)),
          ),
        );
      }),
    );
  }
}
