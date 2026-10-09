import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> showTopUpSuccessSheet({
  required BuildContext context,
  required TopUpSucceeded result,
  required WalletScope scope,
}) {
  final balance = result.balance;
  final added = WalletFormat.money(result.amount);
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.success,
    title: 'Money added',
    message: WalletCopy.topUpSuccess(
      scope,
      added: added,
      balance: balance == null ? null : WalletFormat.money(balance),
    ),
    actionLabel: 'Done',
  );
}
