import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/payment_flow_sheets.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/payment_method_list.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _payment = Get.find<TripPaymentController>();
  final _wallet = Get.find<WalletController>();
  final _waitingSheet = PaymentSheetSlot();
  final _checkingSheet = PaymentSheetSlot();
  final _unconfirmedSheet = PaymentSheetSlot();
  late final Worker _stateWorker;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _stateWorker = ever(_payment.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_payment.open(widget.tripId)));
  }

  @override
  void dispose() {
    _stateWorker.dispose();
    _payment.stopWatching();
    super.dispose();
  }

  bool get _ownsState =>
      _waitingSheet.isOpen ||
      _checkingSheet.isOpen ||
      _unconfirmedSheet.isOpen ||
      (ModalRoute.of(context)?.isCurrent ?? false);

  void _closeSheets() {
    _waitingSheet.close(context);
    _checkingSheet.close(context);
    _unconfirmedSheet.close(context);
  }

  void _onState(PaymentState state) {
    if (!mounted || !_ownsState) return;
    switch (state) {
      case PaymentAwaitingDriver():
        _closeSheetsExcept(_waitingSheet);
        _showWaiting();
      case PaymentProcessing() || PaymentChecking():
        _closeSheetsExcept(_checkingSheet);
        _showChecking(state is PaymentChecking);
      case PaymentUnconfirmed():
        _closeSheetsExcept(_unconfirmedSheet);
        _showUnconfirmed();
      case PaymentPaid(:final payment):
        _closeSheets();
        _celebrate(payment);
      case PaymentDeclined(:final reason, :final payment):
        _closeSheets();
        _reject(payment.declineMessage ?? reason.message);
      case PaymentLoading() || PaymentUnavailable() || PaymentChoosing() || PaymentCardEntry():
        _closeSheets();
    }
  }

  void _closeSheetsExcept(PaymentSheetSlot keep) {
    for (final slot in [_waitingSheet, _checkingSheet, _unconfirmedSheet]) {
      if (!identical(slot, keep)) slot.close(context);
    }
  }

  Future<void> _showWaiting() async {
    final cancelled = await _waitingSheet.show(() => showCashWaitingSheet(context: context, controller: _payment));
    if (cancelled != true || !mounted) return;
    await _payment.cancelCash();
  }

  Future<void> _showChecking(bool isChecking) async {
    final left = await _checkingSheet.show(
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

  Future<void> _showUnconfirmed() async {
    final again = await _unconfirmedSheet.show(() => showPaymentUnconfirmedSheet(context: context));
    if (!mounted || again == null) return;
    if (again) {
      await _payment.checkAgain();
    } else {
      context.go(TripWrapUpRoutes.completeOf(widget.tripId));
    }
  }

  void _reject(String message) {
    SangaToast.show(message, tone: SangaToastTone.error);
    _payment.backToChoosing();
  }

  Future<void> _celebrate(TripPayment payment) async {
    if (_isFinishing) return;
    _isFinishing = true;
    await showPaymentPaidSheet(context: context, title: payment.paidTitle, message: payment.paidMessage);
    if (mounted) _finish();
  }

  void _finish() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(TripWrapUpRoutes.completeOf(widget.tripId));
    }
  }

  Future<void> _continue() async {
    final state = _payment.state;
    if (state is! PaymentChoosing) return;
    if (state.selected == PaymentMethod.cash) {
      await _payment.payCash();
      return;
    }
    if (state.selected == PaymentMethod.wallet) {
      await _payment.payWallet();
      return;
    }
    if (state.selected == PaymentMethod.groupWallet) {
      await _payment.payGroupWallet();
      return;
    }
    _payment.beginCard();
    final paid = await context.push<bool>(TripWrapUpRoutes.payCardOf(widget.tripId));
    if (!mounted) return;
    if (paid == true) {
      _finish();
    } else {
      _payment.backToChoosing();
    }
  }

  Future<void> _topUpWallet(int shortBy) async {
    final overview = _wallet.overview;
    final suggestion = overview?.limits.suggestionFor(shortBy);
    await context.push<bool>(WalletRoutes.topUpOf(amount: suggestion));
    if (!mounted) return;
    await _wallet.reloadQuietly();
    if (mounted) _payment.select(PaymentMethod.wallet);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _payment.state;
      final walletState = _wallet.state;
      return PopScope(
        canPop: state is! PaymentProcessing && state is! PaymentChecking && state is! PaymentAwaitingDriver,
        child: SangaPageLayout(
          title: 'Make payment',
          footer: SangaButton.primary(
            label: 'Continue',
            isLoading: state is PaymentProcessing || state is PaymentChecking,
            onPressed: state is PaymentChoosing && state.selected != null ? _continue : null,
          ),
          children: [
            WrapUpAsyncBody(
              isLoading: state is PaymentLoading,
              failure: state is PaymentUnavailable
                  ? WrapUpFailure(
                      title: state.problem == PaymentProblem.connection
                          ? 'We couldn’t load your payment'
                          : state.problem.title,
                      message: state.problem == PaymentProblem.connection
                          ? 'Check your connection and try again.'
                          : state.problem.message,
                      onRetry: _payment.reload,
                    )
                  : null,
              builder: (context) => _PayBody(
                state: state,
                walletState: walletState,
                onSelect: _payment.select,
                onTopUp: _topUpWallet,
                onRetryWallet: _wallet.reload,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PayBody extends StatelessWidget {
  const _PayBody({
    required this.state,
    required this.walletState,
    required this.onSelect,
    required this.onTopUp,
    required this.onRetryWallet,
  });

  final PaymentState state;
  final WalletState walletState;
  final ValueChanged<PaymentMethod> onSelect;
  final ValueChanged<int> onTopUp;
  final VoidCallback onRetryWallet;

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current is! PaymentLoaded) return const SizedBox.shrink();
    final payment = current.payment;
    final walletOption = WalletPayOption.from(walletState, payment.amount);
    final notice = current is PaymentChoosing ? current.notice : null;
    return Column(
      spacing: SangaSpacing.lg,
      children: [
        AmountTile(label: 'Amount to pay', amount: payment.amount),
        if (notice != null) SangaNotice(message: notice.message, tone: SangaTone.warning),
        PaymentMethodList(
          methods: payment.allowedMethods,
          selected: _selectedOf(current),
          lastMethod: payment.lastMethod,
          group: payment.group,
          walletOption: walletOption,
          onSelect: onSelect,
          onTopUp: () => onTopUp(walletOption is WalletShort ? walletOption.shortBy : 0),
          onRetryWallet: onRetryWallet,
        ),
      ],
    );
  }

  PaymentMethod? _selectedOf(PaymentLoaded state) => switch (state) {
    PaymentChoosing(:final selected) => selected,
    PaymentProcessing(:final method) => method,
    PaymentChecking(:final method) => method,
    PaymentUnconfirmed(:final method) => method,
    PaymentCardEntry() || PaymentDeclined() => PaymentMethod.card,
    PaymentAwaitingDriver() => PaymentMethod.cash,
    PaymentPaid(:final payment) => payment.method ?? PaymentMethod.cash,
  };
}
