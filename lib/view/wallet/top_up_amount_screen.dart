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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _focus.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final initial = NumberFormats.moneyOf(widget.initialAmount);
    _topUp.begin(amount: initial);
    if (initial != null) _amount.text = NumberFormats.groupedWhole(initial);
    unawaited(_wallet.open());
  }

  void _pickQuick(Money amount) {
    _amount.text = NumberFormats.groupedWhole(amount);
    _topUp.setAmount(amount);
    _focus.unfocus();
  }

  Future<void> _continue() async {
    _focus.unfocus();
    final done = await context.push<bool>(WalletRoutes.topUpMethodOf(groupId: widget.scope.groupId));
    if (done == true && mounted) context.pop(true);
  }

  Widget _body(WalletState state, Money? amount) => switch (state) {
    WalletLoading() => const SangaSkeleton.heights([72, 40, 40]),
    WalletFailed(:final problem) => SangaFailureMessage(
      title: WalletCopy.loadFailedTitle(widget.scope),
      message: problem.message,
      onRetry: _wallet.reload,
    ),
    WalletLoaded(:final overview) => _form(overview, amount),
  };

  Widget _form(WalletOverview overview, Money? amount) {
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
              maxDigits: limits.maxTopUp.wholeMajor.toString().length,
              onChanged: (value) => _topUp.setAmount(NumberFormats.moneyOf(value)),
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
      final canContinue = amount != null && amount.isPositive;
      return SangaPageLayout(
        title: WalletCopy.addMoney,
        footer: SangaButton.primary(label: SangaAuthCopy.continueLabel, onPressed: canContinue ? _continue : null),
        children: [_body(state, amount)],
      );
    });
  }
}
