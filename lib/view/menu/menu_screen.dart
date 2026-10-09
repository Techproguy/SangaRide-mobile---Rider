import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/router/account_routes.dart';
import 'package:sanga_ride/core/router/wallet_routes.dart';
import 'package:sanga_ride/view/dev/dev_entry.dart';
import 'package:sanga_ride/view/menu/menu_entries.dart';
import 'package:sanga_ride/view/menu/menu_profile.dart';
import 'package:sanga_ride/view/menu/menu_wallet_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Widget _section(BuildContext context, MenuSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        SangaSectionHeader(section.title),
        SangaListGroup(
          children: [
            for (final entry in section.entries)
              SangaListRow.badge(
                icon: entry.icon,
                title: entry.label,
                trailing: entry.trailing ?? SangaListRow.chevron,
                onTap: () => context.push(entry.route),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = Get.find<UserController>();
    return DevEntry(
      child: SangaPageLayout(
        title: 'Menu',
        children: [
          Obx(() => MenuProfile(user: users.user, onTap: () => context.push(AccountRoutes.profile))),
          const SizedBox(height: SangaSpacing.lg),
          MenuWalletCard(onTap: () => context.push(WalletRoutes.wallet)),
          const SizedBox(height: SangaSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.lg,
            children: [for (final section in MenuEntries.sections) _section(context, section)],
          ),
        ],
      ),
    );
  }
}
