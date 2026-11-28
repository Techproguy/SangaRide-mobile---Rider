import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wallet_method_tile.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PaymentMethodList extends StatelessWidget {
  const PaymentMethodList({
    super.key,
    required this.methods,
    required this.selected,
    required this.lastMethod,
    required this.group,
    required this.walletBalance,
    required this.onSelect,
  });

  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final PaymentMethod? lastMethod;
  final PaymentGroup? group;
  final Money? walletBalance;
  final ValueChanged<PaymentMethod> onSelect;

  String _subtitleOf(PaymentMethod method) {
    return method == lastMethod ? 'You paid this way last time' : method.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final method in methods)
          if (method == PaymentMethod.wallet)
            WalletMethodTile(
              balance: walletBalance,
              group: group,
              isSelected: method == selected,
              onSelect: () => onSelect(method),
            )
          else
            SangaOptionCard(
              leading: SangaIconBadge(child: Icon(PaymentMethodIcon.of(method))),
              title: method.label,
              subtitle: _subtitleOf(method),
              isSelected: method == selected,
              onTap: () => onSelect(method),
            ),
      ],
    );
  }
}
