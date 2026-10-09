import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/payment_flow_sheets.dart';
import 'package:sanga_ride/view/widgets/card/card_details_fields.dart';
import 'package:sanga_ride/view/widgets/card/card_form_model.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  final _payment = Get.find<TripPaymentController>();
  final _form = CardFormModel();
  final _sheet = PaymentSheetSlot();
  final _challengeSheet = PaymentSheetSlot();
  final _unconfirmedSheet = PaymentSheetSlot();
  late final Worker _stateWorker;
  late final int? _amount = _payment.payment?.amount;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _stateWorker = ever(_payment.stateRx, _onState);
    if (_payment.state is! PaymentCardEntry) WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
  }

  @override
  void dispose() {
    _stateWorker.dispose();
    _form.dispose();
    super.dispose();
  }

  void _leave() {
    if (mounted && context.canPop()) context.pop(false);
  }

  void _closeSheets({PaymentSheetSlot? except}) {
    for (final slot in [_sheet, _challengeSheet, _unconfirmedSheet]) {
      if (!identical(slot, except)) slot.close(context);
    }
  }

  void _onState(PaymentState state) {
    if (!mounted) return;
    switch (state) {
      case PaymentProcessing() || PaymentChecking():
        _closeSheets(except: _sheet);
        _showProcessing(state is PaymentChecking);
      case PaymentChallenge():
        _closeSheets(except: _challengeSheet);
        _showChallenge();
      case PaymentUnconfirmed():
        _closeSheets(except: _unconfirmedSheet);
        _showUnconfirmed();
      case PaymentPaid(:final payment):
        _closeSheets();
        _celebrate(payment);
      case PaymentDeclined(:final reason, :final payment):
        _closeSheets();
        _showFailure(reason.title, payment.declineMessage ?? reason.message);
      case PaymentLoading() ||
          PaymentUnavailable() ||
          PaymentChoosing() ||
          PaymentCardEntry() ||
          PaymentAwaitingDriver():
        _closeSheets();
    }
  }

  Future<void> _showProcessing(bool isChecking) async {
    final left = await _sheet.show(
      () => showPaymentPendingSheet(
        context: context,
        title: isChecking ? 'Checking your payment' : 'Payment in progress',
        message: isChecking
            ? 'Hang tight while we confirm it with your bank.'
            : 'Hang tight, this only takes a moment.',
        offersEscape: true,
      ),
    );
    if (left == false && mounted) context.go(TripWrapUpRoutes.completeOf(widget.tripId));
  }

  Future<void> _showChallenge() async {
    await _challengeSheet.show(() => showPaymentOtpSheet(context: context, controller: _payment));
  }

  Future<void> _showUnconfirmed() async {
    final again = await _unconfirmedSheet.show(() => showPaymentUnconfirmedSheet(context: context));
    if (!mounted || again == null) return;
    if (again) {
      await _payment.checkAgain();
    } else {
      context.go(TripWrapUpRoutes.completeOf(widget.tripId));
    }
  }

  Future<void> _showFailure(String title, String message) async {
    final retry = await _sheet.show(
      () => showPaymentFailureSheet(
        context: context,
        title: title,
        message: message,
        primaryLabel: 'Try again',
        secondaryLabel: 'Pay with cash instead',
      ),
    );
    if (!mounted || retry == null) return;
    if (retry) {
      _payment.retryCard();
      return;
    }
    _payment.chooseCashInstead();
    _leave();
  }

  Future<void> _celebrate(TripPayment payment) async {
    if (_isFinishing) return;
    _isFinishing = true;
    await showPaymentPaidSheet(context: context, title: payment.paidTitle, message: payment.paidMessage);
    if (mounted) context.pop(true);
  }

  void _submit() {
    final details = _form.take();
    if (details != null) _payment.payCard(details);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    if (amount == null) return const Scaffold();
    return Obx(() {
      final state = _payment.state;
      final notice = state is PaymentCardEntry ? state.notice : null;
      return PopScope(
        canPop: !_payment.isProcessing,
        child: SangaPageLayout(
          title: 'Enter card details',
          footer: ListenableBuilder(
            listenable: _form,
            builder: (context, _) => SangaButton.primary(
              label: 'Pay ${SangaMoney.naira(amount)}',
              onPressed: _form.isValid && !_payment.isProcessing ? _submit : null,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.md,
              children: [
                if (notice != null) SangaNotice(message: notice.message, tone: SangaTone.warning),
                CardDetailsFields(model: _form, onDone: _submit),
              ],
            ),
          ],
        ),
      );
    });
  }
}
