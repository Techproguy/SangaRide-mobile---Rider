import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PendingTransferCard extends StatelessWidget {
  const PendingTransferCard({super.key, required this.transaction, required this.onTap});

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        SangaListRow(
          leading: const SangaIconBadge(size: 40, child: Icon(Icons.hourglass_top_rounded)),
          title: 'Waiting for your ${WalletFormat.money(transaction.amount)} transfer',
          subtitle: 'Tap to check on it',
          titleMaxLines: 2,
          onTap: onTap,
        ),
      ],
    );
  }
}
