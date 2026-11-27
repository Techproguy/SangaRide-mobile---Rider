import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class TripPaymentWaitCopy {
  static const String title = 'Waiting for your driver to finish';
}

class TripPaymentWait extends StatelessWidget {
  const TripPaymentWait({super.key, required this.payment});

  final TripPaymentSummary payment;

  @override
  Widget build(BuildContext context) {
    return SangaNotice(
      title: TripPaymentWaitCopy.title,
      message: payment.waitingMessage,
      tone: SangaTone.neutral,
      icon: Icons.hourglass_top_rounded,
    );
  }
}
