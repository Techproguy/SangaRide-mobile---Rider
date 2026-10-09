import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
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

  static const String _groupPrefix = '/group/:groupId';
  static const String _amountKey = 'amount';
  static const String _resumeKey = 'resume';
  static const String _groupKey = 'groupId';

  static String _pathOf(String template, String? groupId) => groupId == null ? template : '/group/$groupId$template';

  static String walletOf({String? groupId}) => _pathOf(wallet, groupId);

  static String transactionsOf({String? groupId}) => _pathOf(transactions, groupId);

  static String transactionAt(String id, {String? groupId}) => _pathOf(transaction, groupId).replaceFirst(':id', id);

  static String topUpMethodOf({String? groupId}) => _pathOf(topUpMethod, groupId);

  static String topUpCardOf({String? groupId}) => _pathOf(topUpCard, groupId);

  static String topUpOf({int? amount, String? groupId}) {
    final path = _pathOf(topUp, groupId);
    return amount == null ? path : Uri(path: path, queryParameters: {_amountKey: '$amount'}).toString();
  }

  static String topUpTransferStartOf({String? groupId}) => _pathOf(topUpTransfer, groupId);

  static String topUpTransferOf({required String resumeId, String? groupId}) =>
      Uri(path: _pathOf(topUpTransfer, groupId), queryParameters: {_resumeKey: resumeId}).toString();

  static WalletScope _scopeOf(GoRouterState state) {
    final groupId = state.pathParameters[_groupKey];
    return groupId == null ? const WalletScope.personal() : WalletScope.group(groupId);
  }

  static List<RouteBase> _routes(String prefix) => [
    GoRoute(
      path: '$prefix$wallet',
      builder: (context, state) => WalletScreen(scope: _scopeOf(state)),
    ),
    GoRoute(
      path: '$prefix$transactions',
      builder: (context, state) => WalletTransactionsScreen(scope: _scopeOf(state)),
    ),
    GoRoute(
      path: '$prefix$transaction',
      builder: (context, state) => WalletTransactionScreen(scope: _scopeOf(state), id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '$prefix$topUp',
      builder: (context, state) => TopUpAmountScreen(
        scope: _scopeOf(state),
        initialAmount: int.tryParse(state.uri.queryParameters[_amountKey] ?? ''),
      ),
    ),
    GoRoute(
      path: '$prefix$topUpMethod',
      builder: (context, state) => TopUpMethodScreen(scope: _scopeOf(state)),
    ),
    GoRoute(
      path: '$prefix$topUpCard',
      builder: (context, state) => TopUpCardScreen(scope: _scopeOf(state)),
    ),
    GoRoute(
      path: '$prefix$topUpTransfer',
      builder: (context, state) =>
          TopUpTransferScreen(scope: _scopeOf(state), resumeId: state.uri.queryParameters[_resumeKey]),
    ),
  ];

  static final List<RouteBase> all = [..._routes(''), ..._routes(_groupPrefix)];
}
