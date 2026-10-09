import 'package:flutter/material.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balance, this.onAddMoney, this.label = 'Your balance'});

  static const double _softAlpha = 0.78;

  final int balance;
  final String label;
  final VoidCallback? onAddMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SangaSpacing.lg),
      decoration: const BoxDecoration(color: SangaColors.primary, borderRadius: SangaRadii.sheet),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: SangaSpacing.sm,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xs,
              children: [
                Text(
                  label,
                  style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.onPrimary.withValues(alpha: _softAlpha)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    WalletFormat.money(balance),
                    style: SangaTextStyles.display.copyWith(color: SangaColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (onAddMoney != null) SangaPillButton(label: 'Add money', onPressed: onAddMoney!),
        ],
      ),
    );
  }
}
