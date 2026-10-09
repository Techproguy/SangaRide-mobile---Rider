import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GetStartedSheet extends StatelessWidget {
  const GetStartedSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  static const Duration _landingCap = Duration(seconds: 4);

  Future<void> _continueWith(BuildContext context, AuthProvider provider) async {
    final auth = Get.find<AuthController>();
    if (auth.signingInWith != null) return;
    final signedIn = await auth.continueWith(provider);
    if (!signedIn || !context.mounted) return;
    final restore = Get.find<SessionRestore>();
    final stack = await restore.retry().timeout(_landingCap, onTimeout: () => null);
    if (!context.mounted) return;
    if (stack == null) return context.go(SangaRoutes.home);
    await restore.open(stack);
  }

  @override
  Widget build(BuildContext context) {
    final canUseProviders = AuthController.providersAvailable;
    return SangaAuthChoiceSheet(
      onClose: onClose,
      onCreateAccount: () => context.push(SangaRoutes.signUp),
      onLogin: () => context.push(SangaRoutes.signIn),
      onGoogle: canUseProviders ? () => _continueWith(context, AuthProvider.google) : null,
      onApple: canUseProviders ? () => _continueWith(context, AuthProvider.apple) : null,
    );
  }
}
