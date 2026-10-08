import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/wallet/top_up_amount_screen.dart';
import 'package:sanga_ride/view/wallet/top_up_card_screen.dart';
import 'package:sanga_ride/view/wallet/top_up_method_screen.dart';
import 'package:sanga_ride/view/wallet/top_up_transfer_screen.dart';
import 'package:sanga_ride/view/wallet/wallet_screen.dart';
import 'package:sanga_ride/view/wallet/wallet_transaction_screen.dart';
import 'package:sanga_ride/view/wallet/wallet_transactions_screen.dart';

abstract final class WalletRoutes {
  static const String wallet = '/wallet';
  static const String transactions = '/wallet/transactions';
  static const String transaction = '/wallet/transactions/:id';
  static const String topUp = '/wallet/top-up';
  static const String topUpMethod = '/wallet/top-up/method';
  static const String topUpCard = '/wallet/top-up/card';
  static const String topUpTransfer = '/wallet/top-up/transfer';

  static const String _amountKey = 'amount';
  static const String _resumeKey = 'resume';

  static String transactionOf(String id) => transaction.replaceFirst(':id', id);

  static String topUpOf({int? amount}) =>
      amount == null ? topUp : Uri(path: topUp, queryParameters: {_amountKey: '$amount'}).toString();

  static String topUpTransferOf({required String resumeId}) =>
      Uri(path: topUpTransfer, queryParameters: {_resumeKey: resumeId}).toString();

  static final List<RouteBase> all = [
    GoRoute(path: wallet, builder: (context, state) => const WalletScreen()),
    GoRoute(path: transactions, builder: (context, state) => const WalletTransactionsScreen()),
    GoRoute(
      path: transaction,
      builder: (context, state) => WalletTransactionScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: topUp,
      builder: (context, state) =>
          TopUpAmountScreen(initialAmount: int.tryParse(state.uri.queryParameters[_amountKey] ?? '')),
    ),
    GoRoute(path: topUpMethod, builder: (context, state) => const TopUpMethodScreen()),
    GoRoute(path: topUpCard, builder: (context, state) => const TopUpCardScreen()),
    GoRoute(
      path: topUpTransfer,
      builder: (context, state) => TopUpTransferScreen(resumeId: state.uri.queryParameters[_resumeKey]),
    ),
  ];
}
