import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class TransactionVisuals {
  static IconData of(WalletTransaction tx) =>
      tx.kind == TransactionKind.ridePayment && tx.meta.isDelivery ? Icons.inventory_2_rounded : icon(tx.kind);

  static IconData icon(TransactionKind kind) => switch (kind) {
    TransactionKind.rideEarning => Icons.local_taxi_rounded,
    TransactionKind.deliveryEarning => Icons.inventory_2_rounded,
    TransactionKind.tip => Icons.volunteer_activism_rounded,
    TransactionKind.withdrawal => Icons.account_balance_rounded,
    TransactionKind.topUp => Icons.add_card_rounded,
    TransactionKind.ridePayment => Icons.local_taxi_rounded,
    TransactionKind.refund => Icons.undo_rounded,
    TransactionKind.commission => Icons.receipt_long_rounded,
    TransactionKind.adjustment => Icons.card_giftcard_rounded,
  };

  static String flowLabel(TransactionKind kind) => switch (kind) {
    TransactionKind.rideEarning => 'Ride',
    TransactionKind.deliveryEarning => 'Delivery',
    TransactionKind.tip => 'Tip',
    TransactionKind.withdrawal => 'Cash out',
    TransactionKind.topUp => 'Top up',
    TransactionKind.ridePayment => 'Payment',
    TransactionKind.refund => 'Refund',
    TransactionKind.commission => 'Commission',
    TransactionKind.adjustment => 'Credit',
  };

  static Color statusColor(TransactionStatus status) => switch (status) {
    TransactionStatus.pending => SangaColors.warning,
    TransactionStatus.completed => SangaColors.success,
    TransactionStatus.failed => SangaColors.dangerStrong,
    TransactionStatus.reversed => SangaColors.textMuted,
  };

  static Widget statusTag(TransactionStatus status) => switch (status) {
    TransactionStatus.pending => const SangaTag.warning(label: 'Pending'),
    TransactionStatus.completed => const SangaTag.success(label: 'Completed'),
    TransactionStatus.failed => const SangaTag.urgent(label: 'Failed', icon: Icons.error_outline_rounded),
    TransactionStatus.reversed => const SangaTag.scheduled(label: 'Reversed', icon: Icons.undo_rounded),
  };
}
