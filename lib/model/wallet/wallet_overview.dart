import 'package:sanga_ride/model/wallet/wallet_transaction.dart';

class WalletLimits {
  const WalletLimits({required this.minTopUp, required this.maxTopUp});

  factory WalletLimits.fromJson(Map<String, dynamic> json) =>
      WalletLimits(minTopUp: (json['minTopUp'] as num).toInt(), maxTopUp: (json['maxTopUp'] as num).toInt());

  final int minTopUp;
  final int maxTopUp;

  bool contains(int amount) => amount >= minTopUp && amount <= maxTopUp;
}

class VirtualAccount {
  const VirtualAccount({required this.bankName, required this.accountNumber, required this.accountName});

  factory VirtualAccount.fromJson(Map<String, dynamic> json) => VirtualAccount(
    bankName: json['bankName'] as String,
    accountNumber: json['accountNumber'] as String,
    accountName: json['accountName'] as String,
  );

  final String bankName;
  final String accountNumber;
  final String accountName;
}

enum CardBrand {
  visa('visa', 'Visa'),
  mastercard('mastercard', 'Mastercard'),
  verve('verve', 'Verve'),
  other('other', 'Card');

  const CardBrand(this.code, this.label);

  final String code;
  final String label;

  static CardBrand fromCode(String? code) => values.where((brand) => brand.code == code).firstOrNull ?? CardBrand.other;
}

class SavedCard {
  const SavedCard({required this.id, required this.brand, required this.last4, required this.expiry});

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
    id: json['id'] as String,
    brand: CardBrand.fromCode(json['brand'] as String?),
    last4: json['last4'] as String,
    expiry: json['expiry'] as String,
  );

  final String id;
  final CardBrand brand;
  final String last4;
  final String expiry;

  String get title => '${brand.label} •••• $last4';
}

class WalletOverview {
  const WalletOverview({
    required this.balance,
    required this.limits,
    required this.virtualAccount,
    required this.savedCards,
  });

  factory WalletOverview.fromJson(Map<String, dynamic> json) => WalletOverview(
    balance: (json['balance'] as num).toInt(),
    limits: WalletLimits.fromJson(Map<String, dynamic>.from(json['limits'] as Map)),
    virtualAccount: VirtualAccount.fromJson(Map<String, dynamic>.from(json['virtualAccount'] as Map)),
    savedCards: [
      for (final card in json['savedCards'] as List) SavedCard.fromJson(Map<String, dynamic>.from(card as Map)),
    ],
  );

  final int balance;
  final WalletLimits limits;
  final VirtualAccount virtualAccount;
  final List<SavedCard> savedCards;
}

sealed class RecentTransactions {
  const RecentTransactions();
}

final class RecentLoading extends RecentTransactions {
  const RecentLoading();
}

final class RecentFailed extends RecentTransactions {
  const RecentFailed();
}

final class RecentLoaded extends RecentTransactions {
  const RecentLoaded(this.entries);

  final List<WalletTransaction> entries;

  WalletTransaction? get pendingTransfer => entries.where((entry) => entry.isPendingTransfer).firstOrNull;
}

sealed class WalletState {
  const WalletState();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletFailed extends WalletState {
  const WalletFailed();
}

final class WalletLoaded extends WalletState {
  const WalletLoaded(this.overview, this.recent);

  final WalletOverview overview;
  final RecentTransactions recent;
}
