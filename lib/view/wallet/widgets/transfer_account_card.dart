import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CopyableValue {
  const CopyableValue({required this.label, required this.value});

  final String label;
  final String value;
}

class TransferAccountCard extends StatelessWidget {
  const TransferAccountCard({super.key, required this.account, required this.amount, required this.onCopy});

  final VirtualAccount account;
  final int amount;
  final ValueChanged<CopyableValue> onCopy;

  @override
  Widget build(BuildContext context) {
    return SangaSectionCard(
      title: WalletCopy.transferToAccount,
      subtitle: WalletCopy.sendExactly(amount),
      children: [
        _AccountRow(
          label: WalletCopy.accountNumber,
          value: account.accountNumber,
          copy: CopyableValue(label: WalletCopy.accountNumber, value: account.accountNumber),
          onCopy: onCopy,
        ),
        _AccountRow(label: WalletCopy.bank, value: account.bankName),
        _AccountRow(label: WalletCopy.accountName, value: account.accountName),
        _AccountRow(
          label: WalletCopy.amountToSend,
          value: WalletFormat.money(amount),
          copy: CopyableValue(label: WalletCopy.amount, value: '$amount'),
          onCopy: onCopy,
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value, this.copy, this.onCopy});

  final String label;
  final String value;
  final CopyableValue? copy;
  final ValueChanged<CopyableValue>? onCopy;

  @override
  Widget build(BuildContext context) {
    final toCopy = copy;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
      child: Row(
        spacing: SangaSpacing.sm,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xxs,
              children: [
                Text(label, style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.textMuted)),
                Text(value, style: SangaTextStyles.cardTitleStrong),
              ],
            ),
          ),
          if (toCopy != null) _CopyButton(label: label, onPressed: () => onCopy?.call(toCopy)),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: WalletCopy.copyLabel(label),
      excludeSemantics: true,
      child: Material(
        color: SangaColors.primaryTint,
        borderRadius: SangaRadii.pill,
        child: InkWell(
          borderRadius: SangaRadii.pill,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.sm, vertical: SangaSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: SangaSpacing.xxs,
              children: [
                const Icon(Icons.copy_rounded, size: 18, color: SangaColors.primary),
                Text(WalletCopy.copy, style: SangaTextStyles.action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
