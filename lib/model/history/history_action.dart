import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_detail.dart';

enum HistoryAction {
  shareReceipt('Share receipt', 'Send a copy of the receipt', Icons.ios_share_rounded),
  blockDriver('Block driver', 'You won’t be matched again', Icons.block_rounded, isDestructive: true),
  unblockDriver('Unblock driver', 'Allow matches with this driver again', Icons.lock_open_rounded);

  const HistoryAction(this.label, this.subtitle, this.icon, {this.isDestructive = false});

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isDestructive;

  static List<HistoryAction> availableFor(HistoryDetail detail) {
    final driver = detail.driver;
    return [if (detail.hasReceipt) shareReceipt, if (driver != null) driver.isBlocked ? unblockDriver : blockDriver];
  }
}
