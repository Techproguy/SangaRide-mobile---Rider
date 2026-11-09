import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/services/checkout_page.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_otp_sheet.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_sheets.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_success_sheet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TopUpCardScreen extends StatefulWidget {
  const TopUpCardScreen({super.key, this.scope = const WalletScope.personal()});

  final WalletScope scope;

  @override
  State<TopUpCardScreen> createState() => _TopUpCardScreenState();
}

class _TopUpCardScreenState extends State<TopUpCardScreen> {
  late final _wallet = WalletControllers.wallet(widget.scope);
  late final _topUp = WalletControllers.topUp(widget.scope);
  final _processing = PaymentSheetSlot();
  final _otp = PaymentSheetSlot();
  late final Worker _stateWorker;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _stateWorker = ever(_topUp.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onState(_topUp.state);
    });
  }

  @override
  void dispose() {
    _stateWorker.dispose();
    super.dispose();
  }

  void _closeSheets() {
    _otp.close(context);
    _processing.close(context);
  }

  void _onState(TopUpState state) {
    if (!mounted) return;
    switch (state) {
      case TopUpSubmitting(method: TopUpMethod.card) || TopUpConfirming() || TopUpChecking(method: TopUpMethod.card):
        _showProcessing();
      case TopUpCheckout(:final topUp):
        _showProcessing();
        unawaited(_openCheckout(topUp));
      case TopUpOtp():
        _processing.close(context);
        _showOtp();
      case TopUpSucceeded():
        _closeSheets();
        _celebrate(state);
      case TopUpStillProcessing():
        _closeSheets();
        _showStillProcessing();
      case TopUpUnknown(method: TopUpMethod.card):
        _closeSheets();
        _showUnknown();
      case TopUpFailed(method: TopUpMethod.card, :final failure, :final canRetryAsIs):
        _closeSheets();
        _showFailure(failure, canRetryAsIs: canRetryAsIs);
      case TopUpEditing() ||
          TopUpSubmitting() ||
          TopUpChecking() ||
          TopUpUnknown() ||
          TopUpTransferWatching() ||
          TopUpTransferDelayed() ||
          TopUpFailed():
        _closeSheets();
    }
  }

  Future<void> _openCheckout(TopUp topUp) async {
    final url = topUp.authorizationUrl;
    final isOpen = url != null && await openCheckoutPage(url);
    if (!mounted) return;
    if (isOpen) {
      _topUp.checkoutOpened();
    } else {
      await _topUp.checkoutUnavailable();
    }
  }

  Future<void> _showProcessing() async {
    final shouldLeave = await _processing.show(() => showTopUpProcessingSheet(context: context, controller: _topUp));
    if (shouldLeave == true && mounted) context.pop(true);
  }

  Future<void> _showOtp() async {
    await _otp.show(() => showTopUpOtpSheet(context: context, controller: _topUp));
  }

  Future<void> _showStillProcessing() async {
    final checksWallet = await _processing.show(() => showTopUpStillProcessingSheet(context: context));
    if (!mounted || checksWallet == null) return;
    if (checksWallet) {
      unawaited(_wallet.reloadQuietly());
      context.pop(true);
      return;
    }
    _topUp.keepWatching();
  }

  Future<void> _showUnknown() async {
    final checksWallet = await _processing.show(() => showTopUpUnknownSheet(context: context));
    if (!mounted || checksWallet == null) return;
    if (checksWallet) {
      unawaited(_wallet.reloadQuietly());
      context.pop(true);
      return;
    }
    unawaited(_topUp.recheck());
  }

  Future<void> _showFailure(TopUpFailure failure, {required bool canRetryAsIs}) async {
    final retry = await _processing.show(
      () => showPaymentFailureSheet(
        context: context,
        title: failure.title,
        message: failure.message,
        primaryLabel: SangaCommonCopy.tryAgain,
        secondaryLabel: WalletCopy.pickAnotherWay,
      ),
    );
    if (!mounted || retry == null) return;
    if (retry) {
      canRetryAsIs ? unawaited(_topUp.retryCard()) : _topUp.retry();
      return;
    }
    _topUp.retry();
    context.pop(false);
  }

  Future<void> _celebrate(TopUpSucceeded result) async {
    if (_isFinishing) return;
    _isFinishing = true;
    await showTopUpSuccessSheet(context: context, result: result, scope: widget.scope);
    if (mounted) context.pop(true);
  }

  void _submit() => unawaited(_topUp.submitCard());

  @override
  Widget build(BuildContext context) => SangaSensitiveScreen(child: _screen(context));

  Widget _screen(BuildContext context) {
    return Obx(() {
      final amount = _topUp.draft.amount;
      final overview = _wallet.overview;
      final state = _topUp.state;
      final isBusy =
          state is TopUpSubmitting || state is TopUpOtp || state is TopUpConfirming || state is TopUpChecking;
      if (amount == null || overview == null) return const Scaffold();
      return PopScope(
        canPop: !isBusy,
        child: SangaPageLayout(
          title: WalletCopy.addMoney,
          footer: SangaButton.primary(label: WalletCopy.addAmount(amount), onPressed: isBusy ? null : _submit),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.lg,
              children: [
                AmountTile(label: WalletCopy.addingTo(widget.scope), amount: amount),
                const SangaNotice(
                  message: WalletCopy.cardCheckoutNote,
                  tone: SangaTone.neutral,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
