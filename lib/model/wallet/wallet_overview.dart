import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/wallet/wallet_transaction.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class WalletLimits {
  const WalletLimits({required this.minTopUp, required this.maxTopUp});

  factory WalletLimits.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WalletLimits(
      minTopUp: reader.intOr('minTopUp', permissive.minTopUp),
      maxTopUp: reader.intOr('maxTopUp', permissive.maxTopUp),
    );
  }

  static const WalletLimits permissive = WalletLimits(minTopUp: 1, maxTopUp: 10000000);

  final int minTopUp;
  final int maxTopUp;

  bool contains(int amount) => amount >= minTopUp && amount <= maxTopUp;
}

class VirtualAccount {
  const VirtualAccount({required this.bankName, required this.accountNumber, required this.accountName});

  static VirtualAccount? tryFromJson(JsonReader? reader) {
    if (reader == null) return null;
    final number = reader.strOrNull('accountNumber');
    if (number == null || number.isEmpty) return null;
    return VirtualAccount(
      bankName: reader.strOr('bankName', 'Your bank'),
      accountNumber: number,
      accountName: reader.strOr('accountName', ''),
    );
  }

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

  static CardBrand fromCode(String? code) => enumByCode(values, code, (brand) => brand.code, CardBrand.other);
}

class SavedCard {
  const SavedCard({required this.id, required this.brand, required this.last4, required this.expiry});

  factory SavedCard.fromReader(JsonReader reader) => SavedCard(
    id: reader.str('id'),
    brand: CardBrand.fromCode(reader.strOrNull('brand')),
    last4: reader.str('last4'),
    expiry: reader.strOr('expiry', ''),
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

  factory WalletOverview.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WalletOverview(
      balance: reader.integer('balance'),
      limits: WalletLimits.fromJson(reader.objectOrNull('limits')?.raw ?? const {}),
      virtualAccount: VirtualAccount.tryFromJson(reader.objectOrNull('virtualAccount')),
      savedCards: reader.listOf('savedCards', SavedCard.fromReader),
    );
  }

  final int balance;
  final WalletLimits limits;
  final VirtualAccount? virtualAccount;
  final List<SavedCard> savedCards;

  bool get canPayByTransfer => virtualAccount != null;
}

sealed class RecentTransactions {
  const RecentTransactions();
}

final class RecentLoading extends RecentTransactions {
  const RecentLoading();
}

final class RecentFailed extends RecentTransactions {
  const RecentFailed(this.problem);

  final LoadProblem problem;
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
  const WalletFailed(this.problem);

  final LoadProblem problem;
}

final class WalletLoaded extends WalletState {
  const WalletLoaded(this.overview, this.recent, {this.isStale = false});

  final WalletOverview overview;
  final RecentTransactions recent;
  final bool isStale;

  WalletLoaded markStale() => WalletLoaded(overview, recent, isStale: true);
}
