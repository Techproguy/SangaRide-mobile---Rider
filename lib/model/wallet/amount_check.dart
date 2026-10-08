import 'package:sanga_ride/model/wallet/wallet_overview.dart';

enum AmountProblem { tooLow, tooHigh }

extension WalletLimitChecks on WalletLimits {
  static const List<int> _quickAmounts = [1000, 2000, 5000, 10000, 20000];
  static const int _suggestionStep = 500;

  AmountProblem? problemWith(int amount) {
    if (amount < minTopUp) return AmountProblem.tooLow;
    if (amount > maxTopUp) return AmountProblem.tooHigh;
    return null;
  }

  List<int> get quickAmounts => [
    for (final amount in _quickAmounts)
      if (contains(amount)) amount,
  ];

  int suggestionFor(int shortBy) {
    final rounded = (shortBy / _suggestionStep).ceil() * _suggestionStep;
    return rounded.clamp(minTopUp, maxTopUp);
  }
}
