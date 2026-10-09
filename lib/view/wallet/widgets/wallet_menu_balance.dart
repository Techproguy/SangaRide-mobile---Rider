import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletMenuBalance extends StatefulWidget {
  const WalletMenuBalance({super.key});

  @override
  State<WalletMenuBalance> createState() => _WalletMenuBalanceState();
}

class _WalletMenuBalanceState extends State<WalletMenuBalance> {
  final _wallet = Get.find<WalletController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_wallet.openIfStale()));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        Obx(() {
          final state = _wallet.state;
          return switch (state) {
            WalletLoaded(:final overview) => Text(
              WalletFormat.money(overview.balance),
              style: SangaTextStyles.cardValue,
            ),
            WalletLoading() || WalletFailed() => const SizedBox.shrink(),
          };
        }),
        SangaListRow.chevron,
      ],
    );
  }
}
