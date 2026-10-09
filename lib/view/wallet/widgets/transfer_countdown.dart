import 'package:flutter/material.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransferCountdown extends StatelessWidget {
  const TransferCountdown({super.key, required this.expiresAt, required this.onElapsed});

  final DateTime expiresAt;
  final VoidCallback onElapsed;

  @override
  Widget build(BuildContext context) {
    return SangaCountdown.server(
      endsAt: expiresAt,
      onFinished: onElapsed,
      builder: (context, remaining) => Text(
        WalletCopy.countdownLabel(remaining),
        textAlign: TextAlign.center,
        style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.textMuted),
      ),
    );
  }
}
