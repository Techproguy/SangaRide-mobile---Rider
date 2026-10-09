import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.recent,
    required this.scope,
    required this.onSeeAll,
    required this.onOpen,
    required this.onRetry,
    this.onAddMoney,
  });

  final RecentTransactions recent;
  final WalletScope scope;
  final VoidCallback onSeeAll;
  final ValueChanged<WalletTransaction> onOpen;
  final VoidCallback onRetry;
  final VoidCallback? onAddMoney;

  @override
  Widget build(BuildContext context) {
    final current = recent;
    final hasEntries = current is RecentLoaded && current.entries.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        SangaSectionHeader(
          WalletCopy.transactionHistory,
          actionLabel: hasEntries ? WalletCopy.seeAll : null,
          onAction: onSeeAll,
        ),
        switch (current) {
          RecentLoading() => const SangaSkeleton.heights([56, 56]),
          RecentFailed(:final problem) => SangaFailureMessage(
            title: WalletCopy.historyFailedTitle(scope),
            message: problem.message,
            onRetry: onRetry,
          ),
          RecentLoaded(:final entries) when entries.isEmpty => SangaEmptyMessage(
            icon: Icons.history_rounded,
            title: WalletCopy.noTransactionsYet,
            message: WalletCopy.emptyHistoryMessage(scope),
            actionLabel: onAddMoney == null ? null : WalletCopy.addMoney,
            onAction: onAddMoney,
          ),
          RecentLoaded(:final entries) => SangaListGroup(
            children: [
              for (final entry in entries)
                TransactionRow(transaction: entry, showDate: true, onTap: () => onOpen(entry)),
            ],
          ),
        },
      ],
    );
  }
}
