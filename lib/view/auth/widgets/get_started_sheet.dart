import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GetStartedSheet extends StatelessWidget {
  const GetStartedSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _continueWith(BuildContext context, AuthProvider provider) async {
    final signedIn = await Get.find<AuthController>().continueWith(provider);
    if (signedIn && context.mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return SangaAuthChoiceSheet(
      onClose: onClose,
      onCreateAccount: () => context.push(SangaRoutes.signUp),
      onLogin: () => context.push(SangaRoutes.signIn),
      onGoogle: () => _continueWith(context, AuthProvider.google),
      onApple: () => _continueWith(context, AuthProvider.apple),
    );
  }
}
