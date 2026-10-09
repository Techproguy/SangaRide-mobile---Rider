import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_visuals.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.transaction, required this.onTap, this.showDate = false});

  static const double _arrowSize = 14;

  final WalletTransaction transaction;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return SangaListRow(
      leading: SangaIconBadge(size: 40, child: Icon(TransactionVisuals.of(tx))),
      title: tx.title,
      subtitle: showDate ? WalletFormat.recent(tx.createdAt) : WalletFormat.clock(tx.createdAt),
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: SangaSpacing.xxs,
        children: [
          Text(WalletFormat.signed(tx.amount), style: SangaTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)),
          _FlowLabel(transaction: tx, arrowSize: _arrowSize),
        ],
      ),
    );
  }
}

class _FlowLabel extends StatelessWidget {
  const _FlowLabel({required this.transaction, required this.arrowSize});

  final WalletTransaction transaction;
  final double arrowSize;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    if (tx.status != TransactionStatus.completed) {
      return Text(
        tx.status.label,
        style: SangaTextStyles.cardSubtitle.copyWith(color: TransactionVisuals.statusColor(tx.status)),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.xxs,
      children: [
        Text(TransactionVisuals.flowLabel(tx.kind), style: SangaTextStyles.cardSubtitle),
        Icon(
          tx.isCredit ? Icons.south_rounded : Icons.north_rounded,
          size: arrowSize,
          color: tx.isCredit ? SangaColors.success : SangaColors.dangerStrong,
        ),
      ],
    );
  }
}
