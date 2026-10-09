import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/widgets/transfer_countdown.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show LinkState;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransferWaitingView extends StatelessWidget {
  const TransferWaitingView({super.key, required this.expectation, required this.link, required this.onElapsed});

  final TransferExpectation expectation;
  final LinkState link;
  final VoidCallback onElapsed;

  @override
  Widget build(BuildContext context) {
    final expiresAt = expectation.expiresAt;
    return Column(
      spacing: SangaSpacing.md,
      children: [
        const SizedBox(height: SangaSpacing.lg),
        const SangaActivityIndicator(size: 32),
        Column(
          spacing: SangaSpacing.xs,
          children: [
            Text(WalletCopy.waitingTitle, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
            Text(
              WalletCopy.watching(expectation.amount),
              textAlign: TextAlign.center,
              style: SangaTextStyles.statusMessage,
            ),
            if (expiresAt != null) TransferCountdown(expiresAt: expiresAt, onElapsed: onElapsed),
          ],
        ),
        if (link != LinkState.live) const SangaNotice(message: WalletCopy.reconnecting, tone: SangaTone.warning),
        const SangaNotice(message: WalletCopy.canLeavePage, tone: SangaTone.neutral, icon: Icons.info_outline_rounded),
      ],
    );
  }
}

class TransferDelayedView extends StatelessWidget {
  const TransferDelayedView({
    super.key,
    required this.expectation,
    required this.account,
    required this.link,
    required this.onElapsed,
  });

  final TransferExpectation expectation;
  final VirtualAccount? account;
  final LinkState link;
  final VoidCallback onElapsed;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    final expiresAt = expectation.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        const SizedBox(height: SangaSpacing.lg),
        const Center(child: SangaIconBadge(size: 56, child: Icon(Icons.hourglass_top_rounded))),
        Column(
          spacing: SangaSpacing.xs,
          children: [
            Text(WalletCopy.notSeenTitle, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
            Text(WalletCopy.notSeenMessage, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
            if (expiresAt != null) TransferCountdown(expiresAt: expiresAt, onElapsed: onElapsed),
          ],
        ),
        if (link != LinkState.live) const SangaNotice(message: WalletCopy.reconnecting, tone: SangaTone.warning),
        SangaSectionCard(
          title: WalletCopy.stillMissing,
          children: [
            _Tip(WalletCopy.checkSentExactly(expectation.amount)),
            if (account != null) _Tip(WalletCopy.checkAccountNumber(account.accountNumber, account.bankName)),
            const _Tip(WalletCopy.checkBankApp),
          ],
        ),
      ],
    );
  }
}

class TransferCheckingView extends StatelessWidget {
  const TransferCheckingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        const SizedBox(height: SangaSpacing.xxl),
        const SangaActivityIndicator(size: 32),
        Text(WalletCopy.checkingTitle, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        Text(WalletCopy.checkingMessage, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
      ],
    );
  }
}

class TransferUnknownView extends StatelessWidget {
  const TransferUnknownView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: SangaSpacing.lg),
      child: SangaInlineMessage(
        icon: Icons.hourglass_top_rounded,
        tone: SangaMessageTone.warning,
        title: WalletCopy.unknownTitle,
        message: WalletCopy.unknownTransferMessage,
      ),
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
      child: SangaInlineMessage(
        icon: Icons.account_balance_rounded,
        tone: SangaMessageTone.warning,
        title: failure.title,
        message: failure.message,
      ),
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
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: SangaColors.primary),
          Expanded(child: Text(text, style: SangaTextStyles.cardTitle)),
        ],
      ),
    );
  }
}
