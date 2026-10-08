import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/saved_card_picker.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_otp_sheet.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_success_sheet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride/view/widgets/card/card_details_fields.dart';
import 'package:sanga_ride/view/widgets/card/card_form_model.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TopUpCardScreen extends StatefulWidget {
  const TopUpCardScreen({super.key});

  @override
  State<TopUpCardScreen> createState() => _TopUpCardScreenState();
}

class _TopUpCardScreenState extends State<TopUpCardScreen> {
  final _wallet = Get.find<WalletController>();
  final _topUp = Get.find<TopUpController>();
  final _form = CardFormModel(isPinRequired: false);
  final _processing = PaymentSheetSlot();
  final _otp = PaymentSheetSlot();
  late final Worker _stateWorker;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _stateWorker = ever(_topUp.stateRx, _onState);
  }

  @override
  void dispose() {
    _stateWorker.dispose();
    _form.dispose();
    super.dispose();
  }

  void _closeSheets() {
    _otp.close(context);
    _processing.close(context);
  }

  void _onState(TopUpState state) {
    if (!mounted) return;
    switch (state) {
      case TopUpSubmitting(method: TopUpMethod.card) || TopUpConfirming():
        _showProcessing();
      case TopUpOtp():
        _processing.close(context);
        _showOtp();
      case TopUpSucceeded():
        _closeSheets();
        _celebrate(state);
      case TopUpFailed(method: TopUpMethod.card, :final failure):
        _closeSheets();
        _showFailure(failure);
      case TopUpEditing() || TopUpSubmitting() || TopUpTransferWatching() || TopUpTransferDelayed() || TopUpFailed():
        _closeSheets();
    }
  }

  Future<void> _showProcessing() async {
    await _processing.show(
      () => showPaymentPendingSheet(
        context: context,
        title: 'Payment in progress',
        message: 'Hang tight, this only takes a moment.',
      ),
    );
  }

  Future<void> _showOtp() async {
    await _otp.show(() => showTopUpOtpSheet(context: context, controller: _topUp));
  }

  Future<void> _showFailure(TopUpFailure failure) async {
    final retry = await _processing.show(
      () => showPaymentFailureSheet(
        context: context,
        title: failure.title,
        message: failure.message,
        primaryLabel: 'Try again',
        secondaryLabel: failure.mayHaveGoneThrough ? 'Check my wallet' : 'Pick another way',
      ),
    );
    if (!mounted || retry == null) return;
    if (retry) {
      _topUp.retry();
      return;
    }
    if (failure.mayHaveGoneThrough) {
      unawaited(_wallet.reloadQuietly());
      context.pop(true);
      return;
    }
    _topUp.retry();
    context.pop(false);
  }

  Future<void> _celebrate(TopUpSucceeded result) async {
    if (_isFinishing) return;
    _isFinishing = true;
    await showTopUpSuccessSheet(context: context, result: result);
    if (mounted) context.pop(true);
  }

  void _submit() {
    final draft = _topUp.draft;
    if (draft.savedCardId != null) {
      unawaited(_topUp.submitCard(null));
      return;
    }
    final details = _form.take();
    if (details != null) unawaited(_topUp.submitCard(details));
  }

  Widget _cardSection(WalletOverview overview, TopUpDraft draft) {
    final isNewCard = draft.savedCardId == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        if (overview.savedCards.isNotEmpty)
          SavedCardPicker(cards: overview.savedCards, selectedId: draft.savedCardId, onSelect: _topUp.selectSavedCard),
        if (isNewCard) ...[
          CardDetailsFields(model: _form, onDone: _submit),
          SangaCheckRow.text(
            isChecked: draft.saveCard,
            onChanged: _topUp.setSaveCard,
            text: 'Save this card for next time',
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = _topUp.draft;
      final amount = draft.amount;
      final overview = _wallet.overview;
      final isBusy = _topUp.state is TopUpSubmitting || _topUp.state is TopUpOtp || _topUp.state is TopUpConfirming;
      if (amount == null || overview == null) return const Scaffold();
      return PopScope(
        canPop: !isBusy,
        child: SangaPageLayout(
          title: 'Add money',
          footer: ListenableBuilder(
            listenable: _form,
            builder: (context, _) => SangaButton.primary(
              label: 'Add ${WalletFormat.money(amount)}',
              onPressed: !isBusy && (draft.savedCardId != null || _form.isValid) ? _submit : null,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.lg,
              children: [
                AmountTile(label: 'Adding to your wallet', amount: amount),
                _cardSection(overview, draft),
              ],
            ),
          ],
        ),
      );
    });
  }
}
