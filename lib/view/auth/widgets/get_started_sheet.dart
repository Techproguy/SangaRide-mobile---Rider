import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/widgets/social_sign_in_flow.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show SocialProvider;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GetStartedSheet extends StatelessWidget {
  const GetStartedSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(
      () => SangaAuthChoiceSheet(
        onClose: onClose,
        onCreateAccount: () => context.push(SangaRoutes.signUp),
        onLogin: () => context.push(SangaRoutes.signIn),
        onGoogle: () => SocialSignInFlow.run(context, SocialProvider.google),
        onApple: () => SocialSignInFlow.run(context, SocialProvider.apple),
        isGoogleLoading: auth.signingInWith == SocialProvider.google,
        isAppleLoading: auth.signingInWith == SocialProvider.apple,
      ),
    );
  }
}
