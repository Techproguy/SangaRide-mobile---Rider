import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';

abstract final class WalletCopy {
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
      'card' => 'Card',
      'cash' => 'Cash',
      _ => 'Your wallet',
    };
  }
}
