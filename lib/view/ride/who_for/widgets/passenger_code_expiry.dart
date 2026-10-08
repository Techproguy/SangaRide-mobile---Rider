import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PassengerCodeExpiry extends StatelessWidget {
  const PassengerCodeExpiry({super.key, required this.expiresAt, required this.onExpired});

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    return SangaCountdown(
      endsAt: expiresAt,
      onFinished: onExpired,
      builder: (context, remaining) {
        if (remaining == Duration.zero) {
          return Text('This code has expired. Grab a new one below.', style: SangaTextStyles.bodyMedium);
        }
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: remaining.minutesAndSeconds,
                style: SangaTextStyles.bodyMedium.copyWith(color: SangaColors.danger),
              ),
              const TextSpan(text: ' until code expires'),
            ],
          ),
          style: SangaTextStyles.bodyMedium,
        );
      },
    );
  }
}
