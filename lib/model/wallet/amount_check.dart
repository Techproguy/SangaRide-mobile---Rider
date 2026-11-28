import 'package:sanga_ride/model/wallet/wallet_overview.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

extension WalletLimitChecks on WalletLimits {
  // TODO(#270): drop the quick amounts and suggestion step when the wallet sends limits.quickAmounts and limits.suggestionStep
  static const Map<SangaRegion, List<int>> _quickAmounts = {
    SangaRegion.ng: [1000, 2000, 5000, 10000, 20000],
    SangaRegion.us: [5, 10, 25, 50, 100],
  };
  static const Map<SangaRegion, int> _suggestionSteps = {SangaRegion.ng: 500, SangaRegion.us: 5};

  List<Money> get quickAmounts => [
    for (final amount in _quickAmounts[minTopUp.region] ?? const <int>[])
      if (contains(Money.major(amount, minTopUp.currency))) Money.major(amount, minTopUp.currency),
  ];

  Money suggestionFor(Money shortBy) {
    final step = Money.major(_suggestionSteps[shortBy.region] ?? 1, shortBy.currency);
    final rounded = Money((shortBy.minor / step.minor).ceil() * step.minor, shortBy.currency);
    if (rounded < minTopUp) return minTopUp;
    if (rounded > maxTopUp) return maxTopUp;
    return rounded;
  }
}
