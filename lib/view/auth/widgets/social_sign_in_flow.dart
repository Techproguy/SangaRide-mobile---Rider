import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/auth/social_outcome.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show SocialProvider;

abstract final class SocialSignInFlow {
  static const Duration _landingCap = Duration(seconds: 4);

  static Future<void> run(BuildContext context, SocialProvider provider) async {
    final outcome = await Get.find<AuthController>().continueWith(provider);
    if (!context.mounted) return;
    switch (outcome) {
      case SocialSignedIn():
        await _land(context);
      case SocialNeedsSignUp(:final prefill):
        Get.find<RiderSignUpController>().prefill = prefill;
        context.push(SangaRoutes.signUp);
      case SocialStopped():
        break;
    }
  }

  static Future<void> _land(BuildContext context) async {
    final restore = Get.find<SessionRestore>();
    final stack = await restore.retry().timeout(_landingCap, onTimeout: () => null);
    if (!context.mounted) return;
    if (stack == null) return context.go(SangaRoutes.home);
    await restore.open(stack);
  }
}
