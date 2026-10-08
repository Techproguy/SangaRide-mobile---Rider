import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/router/trip_wrapup_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/payment_method_list.dart';
import 'package:sanga_ride/view/widgets/feedback/payment_sheets.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
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
    super.dispose();
  }

  bool get _ownsState => _waitingSheet.isOpen || (ModalRoute.of(context)?.isCurrent ?? false);

  void _onState(PaymentState state) {
    if (!mounted || !_ownsState) return;
    switch (state) {
      case PaymentAwaitingDriver(:final payment):
        _showWaiting(payment.amount);
      case PaymentPaid(:final payment):
        _waitingSheet.close(context);
        _celebrate(payment);
      case PaymentDeclined(:final reason):
        _waitingSheet.close(context);
        _reject(reason.message);
      case PaymentFailed():
        _waitingSheet.close(context);
        _reject(PaymentFailed.message);
      case PaymentLoading() || PaymentUnavailable() || PaymentChoosing() || PaymentCardEntry() || PaymentProcessing():
        _waitingSheet.close(context);
    }
  }

  Future<void> _showWaiting(int amount) async {
    final cancelled = await _waitingSheet.show(
      () => showPaymentPendingSheet(
        context: context,
        title: 'Waiting for your driver to confirm',
        message: 'Hand ${SangaMoney.naira(amount)} to your driver in cash. We’ll let you know once they confirm.',
        cancelLabel: 'Pick another way',
      ),
    );
    if (cancelled != true || !mounted) return;
    await _payment.cancelCash();
    if (mounted && _payment.state is PaymentAwaitingDriver) await _showWaiting(amount);
  }

  void _reject(String message) {
    Toast.error(message);
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
        canPop: state is! PaymentProcessing && state is! PaymentAwaitingDriver,
        child: SangaPageLayout(
          title: 'Make payment',
          footer: SangaButton.primary(
            label: 'Continue',
            isLoading: state is PaymentProcessing,
            onPressed: state is PaymentChoosing ? _continue : null,
          ),
          children: [
            WrapUpAsyncBody(
              isLoading: state is PaymentLoading,
              failure: state is PaymentUnavailable
                  ? WrapUpFailure(
                      title: 'We couldn’t load your payment',
                      message: 'Check your connection and try again.',
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
    return Column(
      spacing: SangaSpacing.lg,
      children: [
        AmountTile(label: 'Amount to pay', amount: payment.amount),
        PaymentMethodList(
          methods: payment.allowedMethods,
          selected: _selectedOf(current),
          lastMethod: payment.lastMethod,
          walletOption: walletOption,
          onSelect: onSelect,
          onTopUp: () => onTopUp(walletOption is WalletShort ? walletOption.shortBy : 0),
          onRetryWallet: onRetryWallet,
        ),
      ],
    );
  }

  PaymentMethod _selectedOf(PaymentLoaded state) => switch (state) {
    PaymentChoosing(:final selected) => selected,
    PaymentProcessing(:final method) => method,
    PaymentFailed(:final method) => method,
    PaymentCardEntry() || PaymentDeclined() => PaymentMethod.card,
    PaymentAwaitingDriver() => PaymentMethod.cash,
    PaymentPaid(:final payment) => payment.method ?? PaymentMethod.cash,
  };
}
