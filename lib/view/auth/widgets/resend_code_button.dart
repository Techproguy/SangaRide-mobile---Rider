import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({super.key, required this.onResend});

  static const cooldown = Duration(seconds: 60);

  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return SangaCountdown(
      duration: cooldown,
      builder: (context, remaining) {
        if (remaining > Duration.zero) {
          return Text('Resend code in ${remaining.inSeconds} seconds', style: SangaTextStyles.caption);
        }
        return TextButton(
          onPressed: onResend,
          child: Text(
            'Resend code',
            style: SangaTextStyles.caption.copyWith(color: SangaColors.primary, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
