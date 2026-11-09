import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/widgets/card/payment_method_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletMethodTile extends StatelessWidget {
  const WalletMethodTile({
    super.key,
    required this.option,
    required this.group,
    required this.isSelected,
    required this.onSelect,
    required this.onTopUp,
    required this.onRetry,
  });

  final WalletPayOption option;
  final PaymentGroup? group;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onTopUp;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final payer = group;
    final icon = SangaIconBadge(child: Icon(PaymentMethodIcon.of(PaymentMethod.wallet, groupKind: payer?.kind)));
    final title = payer == null ? PaymentMethod.wallet.label : '${payer.name} wallet';
    return switch (option) {
      WalletCovers(:final balance) => SangaOptionCard(
        leading: icon,
        title: title,
        subtitle: 'Balance ${WalletFormat.money(balance)}',
        isSelected: isSelected,
        onTap: onSelect,
      ),
      WalletShort(:final shortBy) when payer != null => _UnavailableTile(
        icon: icon,
        title: title,
        subtitle: 'Short by ${WalletFormat.money(shortBy)}. Ask an admin to top it up.',
      ),
      WalletShort(:final shortBy) => _UnavailableTile(
        icon: icon,
        title: title,
        subtitle: 'Top up ${WalletFormat.money(shortBy)} to use your wallet',
        actionLabel: 'Top up',
        onAction: onTopUp,
      ),
      WalletBalanceLoading() => _UnavailableTile(icon: icon, title: title, subtitle: 'Checking your balance'),
      WalletBalanceFailed() => _UnavailableTile(
        icon: icon,
        title: title,
        subtitle: 'We couldn’t check your balance',
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    };
  }
}

class _UnavailableTile extends StatelessWidget {
  const _UnavailableTile({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  static const double _mutedOpacity = 0.55;

  final Widget icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm),
      decoration: BoxDecoration(
        color: SangaColors.surface,
        borderRadius: SangaRadii.field,
        border: Border.all(color: SangaColors.cardBorder),
      ),
      child: Row(
        spacing: SangaSpacing.md,
        children: [
          Opacity(opacity: _mutedOpacity, child: icon),
          Expanded(
            child: Opacity(
              opacity: _mutedOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xxs,
                children: [
                  Text(title, style: SangaTextStyles.cardTitle),
                  Text(subtitle, style: SangaTextStyles.cardSubtitle),
                ],
              ),
            ),
          ),
          if (label != null) SangaTextAction(label: label, onPressed: onAction),
        ],
      ),
    );
  }
}
