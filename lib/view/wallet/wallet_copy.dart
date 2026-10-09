import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';

abstract final class WalletCopy {
  static const String processingTitle = 'Payment in progress';
  static const String processingMessage = 'Hang tight, this only takes a moment.';
  static const String checkingTitle = 'Checking on your payment';
  static const String checkingMessage = 'Hang tight. We’re making sure your money is safe.';
  static const String stillWorkingMessage = 'Still working on it. You can close this and we’ll keep checking.';
  static const String unknownTitle = 'We’re not sure it went through';
  static const String unknownMessage =
      'Your payment may still land. Check your wallet before you try again so you’re never charged twice.';
  static const String unknownTransferMessage =
      'We didn’t hear back from the server. Check your wallet before you try again so there’s only one top up.';
  static const String reconnecting = 'Trouble reaching Sanga. We’ll keep trying.';

  static String resumeTitle(int amount) =>
      amount > 0 ? 'Finish adding ${WalletFormat.money(amount)}' : 'Finish your top up';

  static String resumeSubtitle(TopUpMethod method) =>
      method == TopUpMethod.card ? 'Tap to pick up where you left off' : 'Tap to check on it';

  static String countdownLabel(Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return 'Account details valid for $minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String walletTitle(WalletScope scope) => scope.isGroup ? 'Group wallet' : 'Wallet';

  static String transactionsTitle(WalletScope scope) => scope.isGroup ? 'Group wallet activity' : 'Transaction history';

  static String balanceLabel(WalletScope scope) => scope.isGroup ? 'Group balance' : 'Your balance';

  static String loadFailedTitle(WalletScope scope) =>
      scope.isGroup ? 'We couldn’t load the group wallet' : 'We couldn’t load your wallet';

  static String historyFailedTitle(WalletScope scope) =>
      scope.isGroup ? 'We couldn’t load the wallet history' : 'We couldn’t load your history';

  static String addingTo(WalletScope scope) => scope.isGroup ? 'Adding to the group wallet' : 'Adding to your wallet';

  static String addedTo(WalletScope scope) => scope.isGroup ? 'the group wallet' : 'your wallet';

  static String topUpSuccess(WalletScope scope, {required String added, String? balance}) {
    if (balance == null) return '$added is on its way to ${addedTo(scope)}.';
    return scope.isGroup
        ? '$added is in the group wallet. The balance is $balance.'
        : '$added is in your wallet. Your balance is $balance.';
  }

  static String emptyHistoryMessage(WalletScope scope) => scope.isGroup
      ? 'Add money and the group wallet activity shows up here.'
      : 'Add money and your wallet activity shows up here.';

  static String emptyTransactionsTitle(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => 'No transactions yet',
    TransactionFilter.topUps => 'No top ups yet',
    TransactionFilter.rides => 'No ride payments yet',
    TransactionFilter.credits => 'No refunds or credits',
  };

  static String emptyTransactionsMessage(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => 'Add money and your wallet activity shows up here.',
    TransactionFilter.topUps => 'Money you add to your wallet shows up here.',
    TransactionFilter.rides => 'Pay for a ride with your wallet and it shows up here.',
    TransactionFilter.credits => 'Refunds, bonuses and promo credit land here.',
  };

  static String amountProblem(AmountProblem problem, WalletLimits limits) => switch (problem) {
    AmountProblem.tooLow => 'Add at least ${WalletFormat.money(limits.minTopUp)}',
    AmountProblem.tooHigh => 'You can add up to ${WalletFormat.money(limits.maxTopUp)} at a time',
  };

  static String limitsHint(WalletLimits limits) =>
      'Add ${WalletFormat.money(limits.minTopUp)} to ${WalletFormat.money(limits.maxTopUp)} at a time.';

  static String paidWith(TransactionMeta meta) {
    if (meta.method == 'transfer') return 'Bank transfer';
    final last4 = meta.cardLast4;
    if (meta.method == 'card' && last4 != null) {
      final brand = CardBrand.fromCode(meta.cardBrand);
      return '${brand.label} •••• $last4';
    }
    return switch (meta.paymentMethod) {
      'wallet' => 'Your wallet',
      'group_wallet' => 'Group wallet',
      'card' => 'Card',
      'cash' => 'Cash',
      _ => 'Your wallet',
    };
  }
}
