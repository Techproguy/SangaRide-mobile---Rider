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

Future<void> showPaymentOtpSheet({required BuildContext context, required TripPaymentController controller}) {
  return showSangaSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: paymentSheetPadding,
    builder: (context) => PopScope(
      canPop: false,
      child: Obx(() {
        final state = controller.state;
        if (state is! PaymentChallenge) return const SizedBox.shrink();
        return PaymentOtpContent(
          message: state.action.message,
          codeLength: state.action.codeLength,
          stage: state.stage,
          onSubmit: controller.submitOtp,
          onEdit: controller.editOtp,
          onCancel: controller.cancelChallenge,
        );
      }),
    ),
  );
}

class PaymentOtpContent extends StatefulWidget {
  const PaymentOtpContent({
    super.key,
    required this.message,
    required this.codeLength,
    required this.stage,
    required this.onSubmit,
    required this.onEdit,
    required this.onCancel,
  });

  static const String mismatchMessage = 'That code didn’t match. Check it and try again.';

  final String message;
  final int codeLength;
  final PaymentChallengeStage stage;
  final ValueChanged<String> onSubmit;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  State<PaymentOtpContent> createState() => _PaymentOtpContentState();
}

class _PaymentOtpContentState extends State<PaymentOtpContent> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(_refresh);
  }

  @override
  void didUpdateWidget(PaymentOtpContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameMismatch =
        widget.stage == PaymentChallengeStage.mismatch && oldWidget.stage != PaymentChallengeStage.mismatch;
    if (becameMismatch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _code.clear();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _changed(String value) {
    if (widget.stage == PaymentChallengeStage.mismatch && value.isNotEmpty) widget.onEdit();
  }

  void _submit() {
    if (_code.text.length == widget.codeLength) widget.onSubmit(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying = widget.stage == PaymentChallengeStage.verifying;
    final message = widget.message.isEmpty ? 'Enter the code your bank just sent you.' : widget.message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm with your bank', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        const SizedBox(height: SangaSpacing.xs),
        Text(message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
        const SizedBox(height: SangaSpacing.lg),
        Center(
          child: SangaOtpField(
            length: widget.codeLength,
            controller: _code,
            alignment: CrossAxisAlignment.center,
            errorText: widget.stage == PaymentChallengeStage.mismatch ? PaymentOtpContent.mismatchMessage : null,
            onChanged: _changed,
            onCompleted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaButton.primary(
          label: 'Confirm',
          isLoading: isVerifying,
          onPressed: _code.text.length == widget.codeLength ? _submit : null,
        ),
        const SizedBox(height: SangaSpacing.xs),
        TextButton(
          onPressed: isVerifying ? null : widget.onCancel,
          child: Text('Cancel', style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
        ),
      ],
    );
  }
}
