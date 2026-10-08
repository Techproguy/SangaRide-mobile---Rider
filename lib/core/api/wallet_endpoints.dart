abstract final class WalletEndpoints {
  static const String wallet = '/wallet';
  static const String transactions = '/wallet/transactions';
  static const String transaction = '/wallet/transactions/:id';
  static const String topUps = '/wallet/top-ups';
  static const String topUp = '/wallet/top-ups/:id';
  static const String topUpAuthorize = '/wallet/top-ups/:id/authorize';

  static String transactionOf(String id) => transaction.replaceFirst(':id', id);

  static String topUpOf(String id) => topUp.replaceFirst(':id', id);

  static String topUpAuthorizeOf(String id) => topUpAuthorize.replaceFirst(':id', id);
}
