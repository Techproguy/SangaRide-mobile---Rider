import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
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

  void _onState(PaymentState state) {
    if (!mounted) return;
    switch (state) {
      case PaymentProcessing():
        _showProcessing();
      case PaymentPaid(:final payment):
        _sheet.close(context);
        _celebrate(payment);
      case PaymentDeclined(:final reason):
        _sheet.close(context);
        _showFailure(reason.title, reason.message);
      case PaymentFailed():
        _sheet.close(context);
        _showFailure(PaymentFailed.title, PaymentFailed.message);
      case PaymentLoading() ||
          PaymentUnavailable() ||
          PaymentChoosing() ||
          PaymentCardEntry() ||
          PaymentAwaitingDriver():
        _sheet.close(context);
    }
  }

  Future<void> _showProcessing() async {
    await _sheet.show(
      () => showPaymentPendingSheet(
        context: context,
        title: 'Payment in progress',
        message: 'Hang tight, this only takes a moment.',
      ),
    );
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
    return Obx(
      () => PopScope(
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
          children: [CardDetailsFields(model: _form, onDone: _submit)],
        ),
      ),
    );
  }
}
