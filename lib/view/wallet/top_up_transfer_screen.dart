import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/widgets/top_up_success_sheet.dart';
import 'package:sanga_ride/view/wallet/widgets/transfer_account_card.dart';
import 'package:sanga_ride/view/wallet/widgets/transfer_status_views.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show LinkState;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TopUpTransferScreen extends StatefulWidget {
  const TopUpTransferScreen({super.key, this.resumeId, this.scope = const WalletScope.personal()});

  final String? resumeId;
  final WalletScope scope;

  @override
  State<TopUpTransferScreen> createState() => _TopUpTransferScreenState();
}

class _TopUpTransferScreenState extends State<TopUpTransferScreen> {
  late final _wallet = WalletControllers.wallet(widget.scope);
  late final _topUp = WalletControllers.topUp(widget.scope);
  late final Worker _stateWorker;
  bool _isFinishing = false;
  bool _isRechecking = false;

  @override
  void initState() {
    super.initState();
    _stateWorker = ever(_topUp.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _stateWorker.dispose();
    _topUp.pause();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    unawaited(_wallet.open());
    final id = widget.resumeId;
    if (id != null) unawaited(_topUp.resumeTransfer(id));
  }

  void _onState(TopUpState state) {
    if (!mounted) return;
    switch (state) {
      case TopUpSucceeded():
        unawaited(_celebrate(state));
      case TopUpFailed(method: TopUpMethod.transfer, canRetryAsIs: true, :final failure):
        SangaToast.show(failure.message, tone: SangaToastTone.warning);
        _topUp.dismissFailure();
      default:
        break;
    }
  }

  Future<void> _celebrate(TopUpSucceeded result) async {
    if (_isFinishing) return;
    _isFinishing = true;
    await showTopUpSuccessSheet(context: context, result: result, scope: widget.scope);
    if (mounted) context.pop(true);
  }

  void _copy(CopyableValue copyable) {
    Clipboard.setData(ClipboardData(text: copyable.value));
    HapticFeedback.selectionClick();
    SangaToast.show('${copyable.label} copied', tone: SangaToastTone.success);
  }

  void _leave() => context.pop(false);

  Future<void> _checkAgain() async {
    if (_isRechecking) return;
    setState(() => _isRechecking = true);
    await _topUp.refreshNow();
    if (mounted) setState(() => _isRechecking = false);
  }

  Widget _body(TopUpState state, int? amount, VirtualAccount? account, LinkState link) {
    if (amount == null && state is! TopUpFailed && state is! TopUpSubmitting) return const SizedBox.shrink();
    return switch (state) {
      TopUpEditing() || TopUpSubmitting() when amount != null && account != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.lg,
        children: [
          AmountTile(label: WalletCopy.addingTo(widget.scope), amount: amount),
          TransferAccountCard(account: account, amount: amount, onCopy: _copy),
        ],
      ),
      TopUpTransferWatching(:final expectation) => TransferWaitingView(
        expectation: expectation,
        link: link,
        onElapsed: () => unawaited(_topUp.refreshNow()),
      ),
      TopUpTransferDelayed(:final expectation) => TransferDelayedView(
        expectation: expectation,
        account: account,
        link: link,
        onElapsed: () => unawaited(_topUp.refreshNow()),
      ),
      TopUpChecking() => const TransferCheckingView(),
      TopUpUnknown() => const TransferUnknownView(),
      TopUpFailed(:final failure) => TransferFailedView(failure: failure),
      _ => const Padding(
        padding: EdgeInsets.only(top: SangaSpacing.xxl),
        child: Center(child: SangaActivityIndicator()),
      ),
    };
  }

  Widget? _footer(TopUpState state, int? amount) => switch (state) {
    TopUpEditing() || TopUpSubmitting() => SangaButton.primary(
      label: 'I’ve sent it',
      isLoading: state is TopUpSubmitting,
      onPressed: state is TopUpEditing && amount != null ? _topUp.confirmTransfer : null,
    ),
    TopUpTransferWatching() => SangaButton.outline(label: 'Done for now', onPressed: _leave),
    TopUpTransferDelayed() => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        SangaButton.primary(label: 'Check again', isLoading: _isRechecking, onPressed: _checkAgain),
        SangaButton.outline(label: 'Done for now', onPressed: _leave),
      ],
    ),
    TopUpUnknown() => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        SangaButton.primary(label: 'Check again', onPressed: () => unawaited(_topUp.recheck())),
        SangaButton.outline(label: 'Check my wallet', onPressed: _leave),
      ],
    ),
    TopUpFailed() => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        if (amount != null) SangaButton.primary(label: 'Start again', onPressed: _topUp.retry),
        SangaButton.outline(label: 'Back to wallet', onPressed: _leave),
      ],
    ),
    TopUpOtp() || TopUpConfirming() || TopUpChecking() || TopUpSucceeded() => null,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _topUp.state;
      final amount = _topUp.draft.amount;
      final account = _wallet.overview?.virtualAccount;
      final link = _topUp.linkRx.value;
      return PopScope(
        canPop: state is! TopUpSubmitting && state is! TopUpChecking,
        child: SangaPageLayout(
          title: 'Add money',
          footer: _footer(state, amount),
          children: [_body(state, amount, account, link)],
        ),
      );
    });
  }
}
