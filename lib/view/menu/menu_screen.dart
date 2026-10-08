import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/view/menu/menu_entries.dart';
import 'package:sanga_ride/view/menu/menu_profile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = Get.find<UserController>();
    return SangaPageLayout(
      title: 'Menu',
      children: [
        Obx(() => MenuProfile(user: users.user)),
        const SizedBox(height: SangaSpacing.xl),
        SangaListGroup(
          children: [
            for (final entry in MenuEntries.all)
              SangaListRow(
                leading: Icon(entry.icon, size: 22, color: SangaColors.textPrimary),
                title: entry.label,
                onTap: () => context.push(entry.route),
              ),
          ],
        ),
      ],
    );
  }
}
