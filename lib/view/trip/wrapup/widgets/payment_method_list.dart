import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wallet_method_tile.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PaymentMethodList extends StatelessWidget {
  const PaymentMethodList({
    super.key,
    required this.methods,
    required this.selected,
    required this.lastMethod,
    required this.walletOption,
    required this.onSelect,
    required this.onTopUp,
    required this.onRetryWallet,
  });

  final List<PaymentMethod> methods;
  final PaymentMethod selected;
  final PaymentMethod? lastMethod;
  final WalletPayOption walletOption;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onTopUp;
  final VoidCallback onRetryWallet;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final method in methods)
          if (method == PaymentMethod.wallet)
            WalletMethodTile(
              option: walletOption,
              isSelected: method == selected,
              onSelect: () => onSelect(method),
              onTopUp: onTopUp,
              onRetry: onRetryWallet,
            )
          else
            SangaOptionCard(
              leading: SangaIconBadge(child: Icon(PaymentMethodIcon.of(method))),
              title: method.label,
              subtitle: method == lastMethod ? 'You paid this way last time' : method.subtitle,
              isSelected: method == selected,
              onTap: () => onSelect(method),
            ),
      ],
    );
  }
}
