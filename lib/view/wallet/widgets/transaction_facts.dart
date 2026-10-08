import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class TransactionFacts {
  static List<Widget> sections(WalletTransaction tx) => [?_notice(tx), _details(tx)];

  static Widget? _notice(WalletTransaction tx) {
    if (tx.isPendingTransfer) {
      return const SangaNotice(
        message:
            'We’re still waiting for your transfer. Banks can take a few minutes, and we add it the moment it lands.',
        tone: SangaTone.neutral,
        icon: Icons.schedule_rounded,
      );
    }
    final reason = tx.meta.failureReason;
    if (tx.status == TransactionStatus.failed && reason != null) {
      return SangaNotice(message: reason, icon: Icons.error_outline_rounded);
    }
    return null;
  }

  static Widget _details(WalletTransaction tx) {
    final meta = tx.meta;
    final route = meta.route;
    final note = meta.note;
    return SangaDetailList(
      title: 'Details',
      rows: [
        SangaDetailRow(icon: Icons.event_rounded, label: 'Date', value: WalletFormat.stamp(tx.createdAt)),
        SangaDetailRow(icon: Icons.tag_rounded, label: 'Reference', value: tx.reference),
        if (tx.kind == TransactionKind.topUp || tx.kind == TransactionKind.ridePayment)
          SangaDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: tx.kind == TransactionKind.topUp ? 'Added with' : 'Paid with',
            value: WalletCopy.paidWith(meta),
          ),
        if (route != null) SangaDetailRow(icon: Icons.route_rounded, label: 'Trip', value: route),
        if (note != null) SangaDetailRow(icon: Icons.notes_rounded, label: 'Note', value: note),
      ],
    );
  }
}
