import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/core/format/number_formats.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TopUpAmountScreen extends StatefulWidget {
  const TopUpAmountScreen({super.key, this.initialAmount, this.scope = const WalletScope.personal()});

  final int? initialAmount;
  final WalletScope scope;

  @override
  State<TopUpAmountScreen> createState() => _TopUpAmountScreenState();
}

class _TopUpAmountScreenState extends State<TopUpAmountScreen> {
  late final _wallet = WalletControllers.wallet(widget.scope);
  late final _topUp = WalletControllers.topUp(widget.scope);
  final _amount = TextEditingController();
  final _focus = FocusNode();
  final RxBool _hasLeftField = false.obs;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _amount.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final initial = widget.initialAmount;
    _topUp.begin(amount: initial);
    if (initial != null) _amount.text = NumberFormats.groupedNigeria.format(initial);
    unawaited(_wallet.open());
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus && _amount.text.isNotEmpty) _hasLeftField.value = true;
  }

  void _pickQuick(int amount) {
    _amount.text = NumberFormats.groupedNigeria.format(amount);
    _topUp.setAmount(amount);
    _focus.unfocus();
  }

  Future<void> _continue() async {
    _focus.unfocus();
    final done = await context.push<bool>(WalletRoutes.topUpMethodOf(groupId: widget.scope.groupId));
    if (done == true && mounted) context.pop(true);
  }

  String? _errorOf(int? amount, WalletLimits limits) {
    if (amount == null) return null;
    final problem = limits.problemWith(amount);
    if (problem == null) return null;
    if (problem == AmountProblem.tooLow && !_hasLeftField.value) return null;
    return WalletCopy.amountProblem(problem, limits);
  }

  Widget _body(WalletState state, int? amount) => switch (state) {
    WalletLoading() => const SangaSkeleton.heights([72, 40, 40]),
    WalletFailed(:final problem) => SangaFailureMessage(
      title: WalletCopy.loadFailedTitle(widget.scope),
      message: problem.message,
      onRetry: _wallet.reload,
    ),
    WalletLoaded(:final overview) => _form(overview, amount),
  };

  Widget _form(WalletOverview overview, int? amount) {
    final limits = overview.limits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.xs,
          children: [
            const SangaFieldLabel(WalletCopy.enterAmount, isRequired: true),
            SangaMoneyField(
              controller: _amount,
              focusNode: _focus,
              hintText: '0',
              maxDigits: limits.maxTopUp.toString().length,
              errorText: _errorOf(amount, limits),
              onChanged: _topUp.setAmount,
              onSubmitted: (_) => _focus.unfocus(),
            ),
            Text(WalletCopy.limitsHint(limits), style: SangaTextStyles.caption),
          ],
        ),
        Wrap(
          spacing: SangaSpacing.sm,
          runSpacing: SangaSpacing.sm,
          children: [
            for (final quick in limits.quickAmounts)
              SangaChoiceChip(
                label: WalletFormat.money(quick),
                isSelected: quick == amount,
                onSelected: (_) => _pickQuick(quick),
              ),
          ],
        ),
        Text(WalletCopy.currentBalance(overview.balance), style: SangaTextStyles.caption),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _wallet.state;
      final amount = _topUp.draft.amount;
      final limits = _wallet.overview?.limits;
      final canContinue = amount != null && limits != null && limits.problemWith(amount) == null;
      return SangaPageLayout(
        title: WalletCopy.addMoney,
        footer: SangaButton.primary(label: WalletCopy.continueLabel, onPressed: canContinue ? _continue : null),
        children: [_body(state, amount)],
      );
    });
  }
}
