import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
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
      title: 'Transfer to this account',
      subtitle: 'Open your bank app and send exactly ${WalletFormat.money(amount)}',
      children: [
        _AccountRow(
          label: 'Account number',
          value: account.accountNumber,
          copy: CopyableValue(label: 'Account number', value: account.accountNumber),
          onCopy: onCopy,
        ),
        _AccountRow(label: 'Bank', value: account.bankName),
        _AccountRow(label: 'Account name', value: account.accountName),
        _AccountRow(
          label: 'Amount to send',
          value: WalletFormat.money(amount),
          copy: CopyableValue(label: 'Amount', value: '$amount'),
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
                Text(value, style: SangaTextStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
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
      label: 'Copy $label',
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
                const Icon(Icons.copy_rounded, size: 14, color: SangaColors.primary),
                Text('Copy', style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
