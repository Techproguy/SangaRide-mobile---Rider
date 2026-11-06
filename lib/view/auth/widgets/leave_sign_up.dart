import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> confirmLeaveSignUp(BuildContext context, {String? phone}) {
  return confirmSangaLeaveSignUp(
    context,
    phone: phone,
    logout: Get.find<AuthController>().logout,
    openSignIn: (phone) => SangaRouter.router.go(SangaRoutes.signIn, extra: phone),
  );
}
