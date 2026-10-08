import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/widgets/layout/amount_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TopUpMethodScreen extends StatelessWidget {
  const TopUpMethodScreen({super.key});

  static const List<TopUpMethod> _methods = [TopUpMethod.transfer, TopUpMethod.card];

  IconData _iconOf(TopUpMethod method) => switch (method) {
    TopUpMethod.transfer => Icons.account_balance_rounded,
    TopUpMethod.card => Icons.credit_card_rounded,
  };

  Future<void> _continue(BuildContext context, TopUpController topUp, TopUpMethod method) async {
    if (method == TopUpMethod.card) topUp.prepareCard();
    final route = switch (method) {
      TopUpMethod.transfer => WalletRoutes.topUpTransfer,
      TopUpMethod.card => WalletRoutes.topUpCard,
    };
    final done = await context.push<bool>(route);
    if (done == true && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final topUp = Get.find<TopUpController>();
    return Obx(() {
      final draft = topUp.draft;
      final amount = draft.amount;
      return SangaPageLayout(
        title: 'Add money',
        footer: SangaButton.primary(label: 'Continue', onPressed: () => _continue(context, topUp, draft.method)),
        children: [
          Column(
            spacing: SangaSpacing.lg,
            children: [
              if (amount != null) AmountTile(label: 'Adding to your wallet', amount: amount),
              Column(
                spacing: SangaSpacing.sm,
                children: [
                  for (final method in _methods)
                    SangaOptionCard(
                      leading: SangaIconBadge(child: Icon(_iconOf(method))),
                      title: method.label,
                      subtitle: method.subtitle,
                      isSelected: method == draft.method,
                      onTap: () => topUp.chooseMethod(method),
                    ),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }
}
