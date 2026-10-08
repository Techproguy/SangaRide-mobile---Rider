import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/wallet/widgets/transaction_visuals.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransactionHero extends StatelessWidget {
  const TransactionHero({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Column(
      spacing: SangaSpacing.xs,
      children: [
        SangaIconBadge(size: 56, child: Icon(TransactionVisuals.icon(tx.kind))),
        const SizedBox(height: SangaSpacing.xxs),
        Text(WalletFormat.signed(tx.amount), style: SangaTextStyles.display),
        Text(tx.title, textAlign: TextAlign.center, style: SangaTextStyles.lead),
        const SizedBox(height: SangaSpacing.xxs),
        TransactionVisuals.statusTag(tx.status),
      ],
    );
  }
}
