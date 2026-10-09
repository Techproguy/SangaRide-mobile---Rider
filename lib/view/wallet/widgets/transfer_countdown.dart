import 'package:flutter/material.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ServerClock;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransferCountdown extends StatefulWidget {
  const TransferCountdown({super.key, required this.expiresAt, required this.onElapsed});

  final DateTime expiresAt;
  final VoidCallback onElapsed;

  @override
  State<TransferCountdown> createState() => _TransferCountdownState();
}

class _TransferCountdownState extends State<TransferCountdown> {
  late DateTime _endsAt = _rebase(widget.expiresAt);

  @override
  void didUpdateWidget(TransferCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) _endsAt = _rebase(widget.expiresAt);
  }

  DateTime _rebase(DateTime deadline) => DateTime.now().add(ServerClock.instance.remaining(deadline));

  @override
  Widget build(BuildContext context) {
    return SangaCountdown(
      endsAt: _endsAt,
      onFinished: widget.onElapsed,
      builder: (context, remaining) => Text(
        WalletCopy.countdownLabel(remaining),
        textAlign: TextAlign.center,
        style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.textMuted),
      ),
    );
  }
}
