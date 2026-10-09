abstract final class WalletEndpoints {
  static const String wallet = '/wallet';
  static const String transactions = '/wallet/transactions';
  static const String transaction = '/wallet/transactions/:id';
  static const String topUps = '/wallet/top-ups';
  static const String topUp = '/wallet/top-ups/:id';
  static const String topUpAuthorize = '/wallet/top-ups/:id/authorize';

  static const String _group = '/groups/:groupId';

  static const String groupWallet = '$_group$wallet';
  static const String groupTransactions = '$_group$transactions';
  static const String groupTransaction = '$_group$transaction';
  static const String groupTopUps = '$_group$topUps';
  static const String groupTopUp = '$_group$topUp';
  static const String groupTopUpAuthorize = '$_group$topUpAuthorize';

  static String _scoped(String personal, String group, String? groupId) =>
      groupId == null ? personal : group.replaceFirst(':groupId', groupId);

  static String walletOf(String? groupId) => _scoped(wallet, groupWallet, groupId);

  static String transactionsOf(String? groupId) => _scoped(transactions, groupTransactions, groupId);

  static String topUpsOf(String? groupId) => _scoped(topUps, groupTopUps, groupId);

  static String transactionAt(String id, {String? groupId}) =>
      _scoped(transaction, groupTransaction, groupId).replaceFirst(':id', id);

  static String topUpAt(String id, {String? groupId}) => _scoped(topUp, groupTopUp, groupId).replaceFirst(':id', id);

  static String topUpAuthorizeAt(String id, {String? groupId}) =>
      _scoped(topUpAuthorize, groupTopUpAuthorize, groupId).replaceFirst(':id', id);
}
