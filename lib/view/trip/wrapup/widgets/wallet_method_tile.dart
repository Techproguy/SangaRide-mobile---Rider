import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletMethodTile extends StatelessWidget {
  const WalletMethodTile({
    super.key,
    required this.balance,
    required this.group,
    required this.isSelected,
    required this.onSelect,
  });

  final Money? balance;
  final PaymentGroup? group;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final payer = group;
    final shown = balance;
    return SangaOptionCard(
      leading: SangaIconBadge(child: Icon(PaymentMethodIcon.of(PaymentMethod.wallet, groupKind: payer?.kind))),
      title: payer == null ? PaymentMethod.wallet.label : '${payer.name} wallet',
      subtitle: shown == null ? PaymentMethod.wallet.subtitle : 'Balance ${WalletFormat.money(shown)}',
      isSelected: isSelected,
      onTap: onSelect,
    );
  }
}
