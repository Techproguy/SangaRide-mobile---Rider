import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MenuWalletCard extends StatefulWidget {
  const MenuWalletCard({super.key, required this.onTap});

  static const double _softAlpha = 0.78;

  final VoidCallback onTap;

  @override
  State<MenuWalletCard> createState() => _MenuWalletCardState();
}

class _MenuWalletCardState extends State<MenuWalletCard> {
  final _wallet = Get.find<WalletController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_wallet.openIfStale()));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Wallet',
      excludeSemantics: true,
      child: Material(
        color: SangaColors.primary,
        borderRadius: SangaRadii.field,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.md),
            child: Row(
              spacing: SangaSpacing.md,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 24, color: SangaColors.onPrimary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SangaSpacing.xxs,
                    children: [
                      Text(
                        'Wallet',
                        style: SangaTextStyles.cardSubtitle.copyWith(
                          color: SangaColors.onPrimary.withValues(alpha: MenuWalletCard._softAlpha),
                        ),
                      ),
                      Obx(() {
                        final balance = _wallet.balance;
                        return Text(
                          balance == null ? 'Open your wallet' : WalletFormat.money(balance),
                          style: SangaTextStyles.title.copyWith(color: SangaColors.onPrimary),
                        );
                      }),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: SangaColors.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
