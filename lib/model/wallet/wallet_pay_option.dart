import 'package:sanga_ride/model/wallet/wallet_overview.dart';

sealed class WalletPayOption {
  const WalletPayOption();

  factory WalletPayOption.from(WalletState state, int fare) => switch (state) {
    WalletLoading() => const WalletBalanceLoading(),
    WalletFailed() => const WalletBalanceFailed(),
    WalletLoaded(:final overview) when overview.balance >= fare => WalletCovers(balance: overview.balance),
    WalletLoaded(:final overview) => WalletShort(balance: overview.balance, shortBy: fare - overview.balance),
  };
}

final class WalletBalanceLoading extends WalletPayOption {
  const WalletBalanceLoading();
}

final class WalletBalanceFailed extends WalletPayOption {
  const WalletBalanceFailed();
}

final class WalletCovers extends WalletPayOption {
  const WalletCovers({required this.balance});

  final int balance;
}

final class WalletShort extends WalletPayOption {
  const WalletShort({required this.balance, required this.shortBy});

  final int balance;
  final int shortBy;
}
