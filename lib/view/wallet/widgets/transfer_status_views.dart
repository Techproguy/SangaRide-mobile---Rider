import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransferWaitingView extends StatelessWidget {
  const TransferWaitingView({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        const SizedBox(height: SangaSpacing.lg),
        const SangaActivityIndicator(),
        Column(
          spacing: SangaSpacing.xs,
          children: [
            Text('Waiting for your transfer', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
            Text(
              'We’re watching for ${WalletFormat.money(amount)} from your bank. This usually takes about a minute.',
              textAlign: TextAlign.center,
              style: SangaTextStyles.statusMessage,
            ),
          ],
        ),
        const SangaNotice(
          message: 'You can leave this page. We’ll add the money as soon as it lands.',
          tone: SangaTone.neutral,
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }
}

class TransferDelayedView extends StatelessWidget {
  const TransferDelayedView({super.key, required this.amount, required this.account});

  final int amount;
  final VirtualAccount? account;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        const SizedBox(height: SangaSpacing.lg),
        const Center(child: SangaIconBadge(size: 56, child: Icon(Icons.hourglass_top_rounded))),
        Column(
          spacing: SangaSpacing.xs,
          children: [
            Text('We haven’t seen it yet', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
            Text(
              'Banks can take a few minutes. If you already sent it, your money is safe and we’ll add it as soon as it lands.',
              textAlign: TextAlign.center,
              style: SangaTextStyles.statusMessage,
            ),
          ],
        ),
        SangaSectionCard(
          title: 'If it’s still missing',
          children: [
            _Tip('Check you sent exactly ${WalletFormat.money(amount)}'),
            if (account != null) _Tip('Check the account number is ${account.accountNumber} (${account.bankName})'),
            const _Tip('Check your bank app shows the transfer as successful'),
          ],
        ),
      ],
    );
  }
}

class TransferFailedView extends StatelessWidget {
  const TransferFailedView({super.key, required this.failure});

  final TopUpFailure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: SangaSpacing.lg),
      child: SangaInlineMessage(title: failure.title, message: failure.message),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.sm,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: SangaColors.primary),
          Expanded(child: Text(text, style: SangaTextStyles.cardTitle)),
        ],
      ),
    );
  }
}
