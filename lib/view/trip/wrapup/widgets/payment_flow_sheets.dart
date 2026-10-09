import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/model/trip/wrapup/payment_state.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<bool?> showPaymentUnconfirmedSheet({required BuildContext context}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: paymentSheetPadding,
    builder: (context) => PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.caution,
        icon: Icons.hourglass_top_rounded,
        title: PaymentUnconfirmed.title,
        message: PaymentUnconfirmed.message,
        action: SangaButton.primary(label: 'Check again', onPressed: () => Navigator.of(context).pop(true)),
        secondary: const PaymentSheetAction(label: 'Close', result: false),
      ),
    ),
  );
}

Future<bool?> showCashWaitingSheet({required BuildContext context, required TripPaymentController controller}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: paymentSheetPadding,
    builder: (context) => PopScope(
      canPop: false,
      child: Obx(() {
        final state = controller.state;
        if (state is! PaymentAwaitingDriver) return const SizedBox.shrink();
        return SangaStatusContent(
          status: SangaStatus.pending,
          title: state.link == CashWaitLink.timedOut
              ? 'Your driver hasn’t confirmed yet'
              : 'Waiting for your driver to confirm',
          message: _cashMessage(state),
          action: state.link == CashWaitLink.timedOut
              ? SangaButton.primary(label: 'Pick another way', onPressed: () => Navigator.of(context).pop(true))
              : null,
          secondary: state.link == CashWaitLink.timedOut
              ? null
              : const PaymentSheetAction(label: 'Pick another way', result: true),
        );
      }),
    ),
  );
}

String _cashMessage(PaymentAwaitingDriver state) {
  final amount = SangaMoney.naira(state.payment.amount);
  return switch (state.link) {
    CashWaitLink.live => 'Hand $amount to your driver in cash. We’ll let you know once they confirm.',
    CashWaitLink.offline => 'You’re offline. We’ll keep checking as soon as you’re back.',
    CashWaitLink.timedOut => 'This is taking longer than usual. Pick another way to pay, or keep waiting.',
  };
}
