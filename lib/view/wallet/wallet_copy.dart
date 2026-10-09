import 'package:sanga_ride/model/trip/wrapup/payment.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';

abstract final class WalletCopy {
  static const String processingTitle = 'Payment in progress';
  static const String processingMessage = CommonCopy.processing;
  static const String checkingTitle = 'Checking on your payment';
  static const String checkingMessage = 'Hang tight. We’re making sure your money is safe.';
  static const String stillWorkingMessage = 'Still working on it. You can close this and we’ll keep checking.';
  static const String unknownTitle = 'We’re not sure it went through';
  static const String unknownMessage =
      'Your payment may still land. Check your wallet before you try again so you’re never charged twice.';
  static const String unknownTransferMessage =
      'We didn’t hear back from the server. Check your wallet before you try again so there’s only one top up.';
  static const String reconnecting = 'Trouble reaching Sanga. We’ll keep trying.';

  static const String addMoney = 'Add money';
  static const String continueLabel = 'Continue';
  static const String enterAmount = 'Enter amount';
  static const String tryAgain = 'Try again';
  static const String pickAnotherWay = 'Pick another way';
  static const String saveCardForNextTime = 'Save this card for next time';
  static const String sentIt = 'I’ve sent it';
  static const String doneForNow = 'Done for now';
  static const String checkAgain = 'Check again';
  static const String checkMyWallet = 'Check my wallet';
  static const String startAgain = 'Start again';
  static const String backToWallet = 'Back to wallet';
  static const String referenceCopied = 'Reference copied';
  static const String checkOnMyTransfer = 'Check on my transfer';
  static const String backToHistory = 'Back to history';
  static const String viewRideDetails = 'View ride details';
  static const String transactionTitle = 'Transaction';
  static const String yourBalance = 'Your balance';
  static const String tapToCheck = 'Tap to check on it';
  static const String transactionHistory = 'Transaction history';
  static const String seeAll = 'See all';
  static const String noTransactionsYet = 'No transactions yet';
  static const String useNewCard = 'Use a new card';
  static const String canSaveForNextTime = 'We can save it for next time';
  static const String otpMismatch = 'That code didn’t match. Check it and try again.';
  static const String confirmWithBank = 'Confirm with your bank';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String moneyAdded = 'Money added';
  static const String done = 'Done';
  static const String stillWaitingForTransfer =
      'We’re still waiting for your transfer. Banks can take a few minutes, and we add it the moment it lands.';
  static const String details = 'Details';
  static const String date = 'Date';
  static const String reference = 'Reference';
  static const String addedWith = 'Added with';
  static const String paidWithLabel = 'Paid with';
  static const String trip = 'Trip';
  static const String note = 'Note';
  static const String flowRide = 'Ride';
  static const String flowDelivery = 'Delivery';
  static const String flowTip = 'Tip';
  static const String flowCashOut = 'Cash out';
  static const String flowTopUp = 'Top up';
  static const String flowPayment = 'Payment';
  static const String flowRefund = 'Refund';
  static const String flowCommission = 'Commission';
  static const String flowCredit = 'Credit';
  static const String statusPending = 'Pending';
  static const String statusCompleted = 'Completed';
  static const String statusFailed = 'Failed';
  static const String statusReversed = 'Reversed';
  static const String statusUpdating = 'Updating';
  static const String transferToAccount = 'Transfer to this account';
  static const String accountNumber = 'Account number';
  static const String bank = 'Bank';
  static const String accountName = 'Account name';
  static const String amountToSend = 'Amount to send';
  static const String amount = 'Amount';
  static const String copy = 'Copy';
  static const String waitingTitle = 'Waiting for your transfer';
  static const String canLeavePage = 'You can leave this page. We’ll add the money as soon as it lands.';
  static const String notSeenTitle = 'We haven’t seen it yet';
  static const String notSeenMessage =
      'Banks can take a few minutes. If you already sent it, your money is safe and we’ll add it as soon as it lands.';
  static const String stillMissing = 'If it’s still missing';
  static const String checkBankApp = 'Check your bank app shows the transfer as successful';

  static String currentBalance(int balance) => 'Current balance ${WalletFormat.money(balance)}';

  static String addAmount(int amount) => 'Add ${WalletFormat.money(amount)}';

  static String copied(String label) => '$label copied';

  static String copyReference(String reference) => 'Copy reference · $reference';

  static String waitingForTransfer(int amount) => 'Waiting for your ${WalletFormat.money(amount)} transfer';

  static String cardExpires(String expiry) => 'Expires $expiry';

  static String sendExactly(int amount) => 'Open your bank app and send exactly ${WalletFormat.money(amount)}';

  static String copyLabel(String label) => 'Copy $label';

  static String watching(int amount) =>
      'We’re watching for ${WalletFormat.money(amount)} from your bank. This usually takes about a minute.';

  static String checkSentExactly(int amount) => 'Check you sent exactly ${WalletFormat.money(amount)}';

  static String checkAccountNumber(String number, String bank) => 'Check the account number is $number ($bank)';

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
    if (meta.isTransfer) return 'Bank transfer';
    final last4 = meta.cardLast4;
    if (meta.method == TopUpMethod.card && last4 != null) {
      final brand = CardBrand.fromCode(meta.cardBrand);
      return '${brand.label} •••• $last4';
    }
    return switch (meta.paymentMethod) {
      null || PaymentMethod.wallet => 'Your wallet',
      final method => method.label,
    };
  }
}
