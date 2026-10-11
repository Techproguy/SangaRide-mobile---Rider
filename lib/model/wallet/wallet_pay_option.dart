import 'package:sanga_ride/model/wallet/wallet_overview.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

sealed class WalletPayOption {
  const WalletPayOption();

  factory WalletPayOption.from(WalletState state, Money fare) => switch (state) {
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

  final Money balance;
}

final class WalletShort extends WalletPayOption {
  const WalletShort({required this.balance, required this.shortBy});

  final Money balance;
  final Money shortBy;
}
